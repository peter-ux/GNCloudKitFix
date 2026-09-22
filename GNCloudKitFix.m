/*
 * GNCloudKitFix.m  (v3.0 — Final)
 * ───────────────────────────────────────────────────────────────────
 * Goodnotes 7.1.19 사이드로딩 CloudKit 크래시 완전 해결 dylib
 *
 * [v3.0 변경점]
 *  v2.0에서 cloudKitContainerOptions=nil 만으로 해결되지 않은 이유:
 *  → Goodnotes 코드가 NSPersistentCloudKitContainer init 과정에서
 *    CKContainer 클래스를 직접 인스턴스화([CKContainer alloc] init)하여
 *    iCloud 계정 상태를 확인함.
 *  → 사이드로딩 환경에서 entitlement가 없으면 CloudKit 프레임워크가
 *    즉시 NSInternalInconsistencyException을 throw.
 *
 * [최종 해결 전략]
 *  1. NSPersistentStoreDescription의 cloudKitContainerOptions를 원천 nil 처리.
 *  2. CKContainer의 +defaultContainer, +containerWithIdentifier: 를 후킹하여
 *     CloudKit entitlement 예외를 @try/@catch로 감싸서 안전하게 nil 반환.
 *  3. NSPersistentCloudKitContainer의 initWithName: 계열을 후킹하여
 *     전체를 @try/@catch로 감싸고, CloudKit 예외 발생 시에도
 *     부모 클래스(NSPersistentContainer)의 init으로 폴백.
 *  4. loadPersistentStores 호출 전 store description을 재확인.
 *  5. NSUbiquitousKeyValueStore synchronize 차단.
 *
 * [안전 장치]
 *  - class_addMethod 기반 안전한 스위즐링 (부모 클래스 오염 방지)
 *  - NSObject init은 절대로 건드리지 않음
 * ───────────────────────────────────────────────────────────────────
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <dlfcn.h>

#define LOG(fmt, ...) NSLog(@"[GNCloudKitFix] " fmt, ##__VA_ARGS__)

// ─────────────────────────────────────────────────────────────────
// 안전한 메서드 스위즐링 헬퍼
// class_addMethod를 먼저 시도하여 부모 클래스(NSObject 등) 오염 방지
// ─────────────────────────────────────────────────────────────────
static BOOL safe_swizzle_instance(Class cls, SEL sel, IMP newIMP, IMP *outOrigIMP) {
    if (!cls) return NO;
    
    Method origMethod = class_getInstanceMethod(cls, sel);
    if (!origMethod) {
        LOG("⚠️ 메서드 없음: -[%s %s]", class_getName(cls), sel_getName(sel));
        return NO;
    }
    
    const char *types = method_getTypeEncoding(origMethod);
    *outOrigIMP = method_getImplementation(origMethod);
    
    if (class_addMethod(cls, sel, newIMP, types)) {
        LOG("✅ 서브클래스 오버라이드: -[%s %s]", class_getName(cls), sel_getName(sel));
    } else {
        *outOrigIMP = class_replaceMethod(cls, sel, newIMP, types);
        LOG("✅ 구현 교체: -[%s %s]", class_getName(cls), sel_getName(sel));
    }
    return YES;
}

static BOOL safe_swizzle_class(Class cls, SEL sel, IMP newIMP, IMP *outOrigIMP) {
    if (!cls) return NO;
    
    // 클래스 메서드는 메타클래스에 존재
    Class metaCls = object_getClass(cls);
    Method origMethod = class_getClassMethod(cls, sel);
    if (!origMethod) {
        LOG("⚠️ 클래스 메서드 없음: +[%s %s]", class_getName(cls), sel_getName(sel));
        return NO;
    }
    
    const char *types = method_getTypeEncoding(origMethod);
    *outOrigIMP = method_getImplementation(origMethod);
    
    if (class_addMethod(metaCls, sel, newIMP, types)) {
        LOG("✅ 메타클래스 오버라이드: +[%s %s]", class_getName(cls), sel_getName(sel));
    } else {
        *outOrigIMP = class_replaceMethod(metaCls, sel, newIMP, types);
        LOG("✅ 메타클래스 구현 교체: +[%s %s]", class_getName(cls), sel_getName(sel));
    }
    return YES;
}

// ─────────────────────────────────────────────────────────────────
// 1. NSPersistentStoreDescription CloudKit 옵션 원천 무력화
// ─────────────────────────────────────────────────────────────────
static void (*orig_setCloudKitContainerOptions)(id, SEL, id) = NULL;
static void hook_setCloudKitContainerOptions(id self, SEL _cmd, id options) {
    // 항상 nil로 강제 — CloudKit 동기화 완전 비활성화
    if (orig_setCloudKitContainerOptions) {
        orig_setCloudKitContainerOptions(self, _cmd, nil);
    }
}

static id (*orig_cloudKitContainerOptions)(id, SEL) = NULL;
static id hook_cloudKitContainerOptions(id self, SEL _cmd) {
    return nil;  // 항상 nil 반환
}

// ─────────────────────────────────────────────────────────────────
// 2. Mock CKContainer (Safe Stub Object)
// ─────────────────────────────────────────────────────────────────
@interface GNMockCKContainer : NSObject
+ (instancetype)sharedMock;
@end

@implementation GNMockCKContainer
+ (instancetype)sharedMock {
    static GNMockCKContainer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GNMockCKContainer alloc] init];
    });
    return instance;
}

- (void)accountStatusWithCompletionHandler:(void(^)(NSInteger accountStatus, NSError *error))completionHandler {
    if (completionHandler) {
        NSError *err = [NSError errorWithDomain:@"CKErrorDomain" code:9 userInfo:@{NSLocalizedDescriptionKey: @"iCloud account not authenticated"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(2 /* CKAccountStatusNoAccount */, err);
        });
    }
}

- (void)statusForApplicationPermission:(NSUInteger)permission completionHandler:(void(^)(NSInteger status, NSError *error))completionHandler {
    if (completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(0 /* CKApplicationPermissionStatusInitialState */, nil);
        });
    }
}

- (id)privateCloudDatabase { return nil; }
- (id)publicCloudDatabase { return nil; }
- (id)sharedCloudDatabase { return nil; }
- (id)containerIdentifier { return @"iCloud.com.goodnotes.container"; }

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
    if (!sig) {
        sig = [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    LOG("GNMockCKContainer ignored method: %s", sel_getName([anInvocation selector]));
}
@end

static id (*orig_ck_defaultContainer)(id, SEL) = NULL;
static id hook_ck_defaultContainer(id self, SEL _cmd) {
    @try {
        if (orig_ck_defaultContainer) {
            id res = orig_ck_defaultContainer(self, _cmd);
            if (res) return res;
        }
    } @catch (NSException *e) {
        LOG("CKContainer.defaultContainer 예외 -> GNMockCKContainer 반환: %@", e.reason);
    }
    return [GNMockCKContainer sharedMock];
}

static id (*orig_ck_containerWithIdentifier)(id, SEL, NSString *) = NULL;
static id hook_ck_containerWithIdentifier(id self, SEL _cmd, NSString *identifier) {
    @try {
        if (orig_ck_containerWithIdentifier) {
            id res = orig_ck_containerWithIdentifier(self, _cmd, identifier);
            if (res) return res;
        }
    } @catch (NSException *e) {
        LOG("CKContainer.containerWithIdentifier: 예외 -> GNMockCKContainer 반환: %@", e.reason);
    }
    return [GNMockCKContainer sharedMock];
}

// ─────────────────────────────────────────────────────────────────
// 3. Helper: Store Description에서 CloudKit 옵션 제거
// ─────────────────────────────────────────────────────────────────
static void neutralize_store_descriptions(id container) {
    if (!container) return;
    
    @try {
        if ([container respondsToSelector:@selector(persistentStoreDescriptions)]) {
            NSArray *descriptions = [container performSelector:@selector(persistentStoreDescriptions)];
            for (id desc in descriptions) {
                if ([desc respondsToSelector:@selector(setCloudKitContainerOptions:)]) {
                    [desc performSelector:@selector(setCloudKitContainerOptions:) withObject:nil];
                }
            }
        }
    } @catch (NSException *e) {
        LOG("neutralize_store_descriptions 예외: %@", e.reason);
    }
}

// ─────────────────────────────────────────────────────────────────
// 4. NSPersistentCloudKitContainer 초기화 가로채기
//    전체를 @try/@catch로 감싸서, CloudKit 예외 발생 시
//    부모 클래스(NSPersistentContainer)의 init으로 폴백
// ─────────────────────────────────────────────────────────────────
static id (*orig_initWithName_managedObjectModel)(id, SEL, NSString *, NSManagedObjectModel *) = NULL;
static id hook_initWithName_managedObjectModel(id self, SEL _cmd, NSString *name, NSManagedObjectModel *model) {
    LOG("initWithName:managedObjectModel: 가로챔 (name: %@)", name);
    
    @try {
        id result = nil;
        if (orig_initWithName_managedObjectModel) {
            result = orig_initWithName_managedObjectModel(self, _cmd, name, model);
        }
        if (result) {
            neutralize_store_descriptions(result);
            LOG("✅ CloudKitContainer '%@' 정상 생성 (로컬 모드)", name);
            return result;
        }
    } @catch (NSException *e) {
        LOG("⚠️ CloudKitContainer init 예외 발생: %@ — NSPersistentContainer로 폴백", e.reason);
    }
    
    // CloudKit init 실패 시 → NSPersistentContainer 새로 생성하여 폴백
    @try {
        Class parentClass = objc_getClass("NSPersistentContainer");
        if (parentClass) {
            id newObj = ((id(*)(Class, SEL))objc_msgSend)(parentClass, sel_registerName("alloc"));
            id fallback = ((id(*)(id, SEL, NSString*, NSManagedObjectModel*))objc_msgSend)(
                newObj,
                @selector(initWithName:managedObjectModel:),
                name, model);
            if (fallback) {
                neutralize_store_descriptions(fallback);
                LOG("✅ NSPersistentContainer 폴백 성공 (name: %@)", name);
                return fallback;
            }
        }
    } @catch (NSException *e2) {
        LOG("❌ NSPersistentContainer 폴백도 실패: %@", e2.reason);
    }
    
    return self;
}

static id (*orig_initWithName)(id, SEL, NSString *) = NULL;
static id hook_initWithName(id self, SEL _cmd, NSString *name) {
    LOG("initWithName: 가로챔 (name: %@)", name);
    
    @try {
        id result = nil;
        if (orig_initWithName) {
            result = orig_initWithName(self, _cmd, name);
        }
        if (result) {
            neutralize_store_descriptions(result);
            LOG("✅ CloudKitContainer '%@' 정상 생성 (로컬 모드)", name);
            return result;
        }
    } @catch (NSException *e) {
        LOG("⚠️ CloudKitContainer initWithName: 예외: %@ — 폴백 시도", e.reason);
    }
    
    @try {
        Class parentClass = objc_getClass("NSPersistentContainer");
        if (parentClass) {
            id newObj = ((id(*)(Class, SEL))objc_msgSend)(parentClass, sel_registerName("alloc"));
            id fallback = ((id(*)(id, SEL, NSString*))objc_msgSend)(
                newObj,
                @selector(initWithName:),
                name);
            if (fallback) {
                neutralize_store_descriptions(fallback);
                LOG("✅ NSPersistentContainer 폴백 성공 (name: %@)", name);
                return fallback;
            }
        }
    } @catch (NSException *e2) {
        LOG("❌ 폴백 실패: %@", e2.reason);
    }
    
    return self;
}

// ─────────────────────────────────────────────────────────────────
// 5. loadPersistentStores 가로채기 (최종 방어선)
// ─────────────────────────────────────────────────────────────────
static void (*orig_loadPersistentStores)(id, SEL, void (^)(NSPersistentStoreDescription *, NSError *)) = NULL;
static void hook_loadPersistentStores(id self, SEL _cmd, void (^block)(NSPersistentStoreDescription *, NSError *)) {
    neutralize_store_descriptions(self);
    
    @try {
        if (orig_loadPersistentStores) {
            orig_loadPersistentStores(self, _cmd, block);
        }
    } @catch (NSException *e) {
        LOG("⚠️ loadPersistentStores 예외 흡수: %@", e.reason);
        // 에러 콜백 호출하여 앱이 에러 핸들링 경로를 탈 수 있게
        if (block) {
            NSError *err = [NSError errorWithDomain:@"GNCloudKitFix"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: e.reason ?: @"CloudKit disabled"}];
            block(nil, err);
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// 6. NSUbiquitousKeyValueStore synchronize 차단
// ─────────────────────────────────────────────────────────────────
static BOOL (*orig_kv_synchronize)(id, SEL) = NULL;
static BOOL hook_kv_synchronize(id self, SEL _cmd) {
    return NO;
}

// ─────────────────────────────────────────────────────────────────
// 생성자: dylib 로드 시 1회 실행
// ─────────────────────────────────────────────────────────────────
__attribute__((constructor))
static void GNCloudKitFix_initialize(void) {
    LOG("══════════════════════════════════════════════════");
    LOG("  GNCloudKitFix v4.2 (Hybrid Timing) 로드           ");
    LOG("══════════════════════════════════════════════════");

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // PHASE 1: IMMEDIATE (constructor) — Must run before didFinishLaunching
    // CKContainer factory + NSPersistentStoreDescription hooks
    // These prevent CloudKit entitlement exceptions during app delegate init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // CoreData/CloudKit 프레임워크 강제 로드
    dlopen("/System/Library/Frameworks/CoreData.framework/CoreData", RTLD_NOW | RTLD_GLOBAL);
    dlopen("/System/Library/Frameworks/CloudKit.framework/CloudKit", RTLD_NOW | RTLD_GLOBAL);

    // ── [1] NSPersistentStoreDescription CloudKit 옵션 무력화 ──
    Class descClass = objc_getClass("NSPersistentStoreDescription");
    if (descClass) {
        safe_swizzle_instance(descClass,
            @selector(setCloudKitContainerOptions:),
            (IMP)hook_setCloudKitContainerOptions,
            (IMP*)&orig_setCloudKitContainerOptions);

        safe_swizzle_instance(descClass,
            @selector(cloudKitContainerOptions),
            (IMP)hook_cloudKitContainerOptions,
            (IMP*)&orig_cloudKitContainerOptions);
        
        LOG("NSPersistentStoreDescription 후킹 완료 (즉시)");
    }

    // ── [2] CKContainer 팩토리 메서드 후킹 ──
    Class ckClass = objc_getClass("CKContainer");
    if (ckClass) {
        safe_swizzle_class(ckClass,
            @selector(defaultContainer),
            (IMP)hook_ck_defaultContainer,
            (IMP*)&orig_ck_defaultContainer);
        
        safe_swizzle_class(ckClass,
            @selector(containerWithIdentifier:),
            (IMP)hook_ck_containerWithIdentifier,
            (IMP*)&orig_ck_containerWithIdentifier);
        
        LOG("CKContainer 팩토리 후킹 완료 (즉시)");
    }

    LOG("Phase 1 완료 — CloudKit 예외 방어 활성화");

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // PHASE 2: DEFERRED (main queue) — Heavier hooks after system init
    // NSPersistentCloudKitContainer + NSUbiquitousKeyValueStore
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    dispatch_async(dispatch_get_main_queue(), ^{
        // ── [3] NSPersistentCloudKitContainer 초기화 후킹 ──
        Class ckContainerClass = objc_getClass("NSPersistentCloudKitContainer");
        if (ckContainerClass) {
            safe_swizzle_instance(ckContainerClass,
                @selector(initWithName:managedObjectModel:),
                (IMP)hook_initWithName_managedObjectModel,
                (IMP*)&orig_initWithName_managedObjectModel);

            safe_swizzle_instance(ckContainerClass,
                @selector(initWithName:),
                (IMP)hook_initWithName,
                (IMP*)&orig_initWithName);

            safe_swizzle_instance(ckContainerClass,
                @selector(loadPersistentStoresWithCompletionHandler:),
                (IMP)hook_loadPersistentStores,
                (IMP*)&orig_loadPersistentStores);
            
            LOG("NSPersistentCloudKitContainer 후킹 완료 (지연)");
        }

        // ── [4] NSUbiquitousKeyValueStore 차단 ──
        Class kvClass = objc_getClass("NSUbiquitousKeyValueStore");
        if (kvClass) {
            safe_swizzle_instance(kvClass,
                @selector(synchronize),
                (IMP)hook_kv_synchronize,
                (IMP*)&orig_kv_synchronize);
            
            LOG("NSUbiquitousKeyValueStore 후킹 완료 (지연)");
        }

        LOG("══════════════════════════════════════════════════");
        LOG("  GNCloudKitFix v4.2 초기화 완료 (Hybrid Active)    ");
        LOG("══════════════════════════════════════════════════");
    });
}