/*
 * GNCloudKitFix.m
 * ───────────────────────────────────────────────────────────────────
 * Goodnotes 7.1.19 사이드로딩 CloudKit 크래시 해결 dylib
 *
 * [원인 분석 결과]
 * 1. Goodnotes 7.1.19는 NSPersistentCloudKitContainer를 사용하여
 *    전역 appContainer를 초기화하며, 100곳 이상의 Swift guard문에서
 *    appContainer != nil 을 강제 검증함.
 * 2. 사이드로딩 환경에서는 iCloud entitlement가 없어 CloudKit 초기화가 실패,
 *    appContainer가 nil이 되어 SceneDelegate 등에서 fatalError로 크래시 발생.
 * 3. 이전 버전의 버그: NSCloudKitMirroringDelegate의 -init을 후킹하려다
 *    상속 체인을 타고 올라가 -[NSObject init] 전체가 nil을 반환하게 됨.
 *    이로 인해 +load 시점에 Datadog(__dd_private_AppLaunchHandler)가
 *    [alloc init] -> nil을 받고 0x10 번지 SIGSEGV로 즉사함.
 *
 * [해결 전략 (Apple 공식 가이드 기반)]
 * 1. NSPersistentStoreDescription의 cloudKitContainerOptions를 완전히 nil로 무력화.
 *    - setCloudKitContainerOptions: 가 호출되어도 항상 nil로 설정.
 *    - cloudKitContainerOptions getter도 항상 nil 반환.
 * 2. NSPersistentCloudKitContainer의 초기화 및 스토어 로드 시점에
 *    모든 store description의 cloudKitContainerOptions를 nil로 강제.
 *    -> 컨테이너 인스턴스는 정상 생성(non-nil)되고, Core Data는
 *       순수 로컬 SQLite(NSSQLCore) 모드로만 동작.
 * 3. NSObject나 상위 클래스의 메서드를 오염시키지 않도록 class_addMethod 기반
 *    안전한 런타임 스위즐링 적용.
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
        LOG("⚠️ 메서드 찾을 수 없음: -[%s %s]", class_getName(cls), sel_getName(sel));
        return NO;
    }
    
    const char *types = method_getTypeEncoding(origMethod);
    *outOrigIMP = method_getImplementation(origMethod);
    
    // 서브클래스에 먼저 추가 시도 (상속된 메서드인 경우 부모 오염 방지)
    if (class_addMethod(cls, sel, newIMP, types)) {
        LOG("✅ 서브클래스 오버라이드 등록 성공: -[%s %s]", class_getName(cls), sel_getName(sel));
    } else {
        // 이미 서브클래스 자체 구현이 있으면 IMP 교체
        *outOrigIMP = class_replaceMethod(cls, sel, newIMP, types);
        LOG("✅ 기존 구현 교체 성공: -[%s %s]", class_getName(cls), sel_getName(sel));
    }
    return YES;
}

// ─────────────────────────────────────────────────────────────────
// 1. NSPersistentStoreDescription CloudKit 옵션 완전 무력화
// ─────────────────────────────────────────────────────────────────
static void (*orig_setCloudKitContainerOptions)(id, SEL, id) = NULL;
static void hook_setCloudKitContainerOptions(id self, SEL _cmd, id options) {
    LOG("NSPersistentStoreDescription setCloudKitContainerOptions: 차단 -> nil 강제");
    if (orig_setCloudKitContainerOptions) {
        orig_setCloudKitContainerOptions(self, _cmd, nil);
    }
}

static id (*orig_cloudKitContainerOptions)(id, SEL) = NULL;
static id hook_cloudKitContainerOptions(id self, SEL _cmd) {
    return nil;
}

// ─────────────────────────────────────────────────────────────────
// 2. Helper: Store Description에서 CloudKit 옵션 제거
// ─────────────────────────────────────────────────────────────────
static void neutralize_store_descriptions(id container, const char *context) {
    if (!container) return;
    
    if ([container respondsToSelector:@selector(persistentStoreDescriptions)]) {
        NSArray *descriptions = [container performSelector:@selector(persistentStoreDescriptions)];
        for (NSPersistentStoreDescription *desc in descriptions) {
            if ([desc respondsToSelector:@selector(setCloudKitContainerOptions:)]) {
                [desc performSelector:@selector(setCloudKitContainerOptions:) withObject:nil];
                LOG("[%s] store url '%@' 의 cloudKitContainerOptions -> nil 설정 완료",
                    context, desc.URL ? desc.URL.lastPathComponent : @"(no url)");
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// 3. NSPersistentCloudKitContainer 초기화 가로채기
// ─────────────────────────────────────────────────────────────────
static id (*orig_initWithName_managedObjectModel)(id, SEL, NSString *, NSManagedObjectModel *) = NULL;
static id hook_initWithName_managedObjectModel(id self, SEL _cmd, NSString *name, NSManagedObjectModel *model) {
    LOG("NSPersistentCloudKitContainer initWithName:managedObjectModel: 호출됨 (name: %@)", name);
    id result = nil;
    if (orig_initWithName_managedObjectModel) {
        result = orig_initWithName_managedObjectModel(self, _cmd, name, model);
    }
    if (result) {
        neutralize_store_descriptions(result, "initWithName:model");
        LOG("✅ 컨테이너 '%@' 정상 생성 및 로컬 SQLite 모드 전환 완료", name);
    }
    return result;
}

static id (*orig_initWithName)(id, SEL, NSString *) = NULL;
static id hook_initWithName(id self, SEL _cmd, NSString *name) {
    LOG("NSPersistentCloudKitContainer initWithName: 호출됨 (name: %@)", name);
    id result = nil;
    if (orig_initWithName) {
        result = orig_initWithName(self, _cmd, name);
    }
    if (result) {
        neutralize_store_descriptions(result, "initWithName");
        LOG("✅ 컨테이너 '%@' 정상 생성 및 로컬 SQLite 모드 전환 완료", name);
    }
    return result;
}

// ─────────────────────────────────────────────────────────────────
// 4. NSPersistentCloudKitContainer loadPersistentStores 가로채기
// (스토어를 디스크에서 열기 직전 최종적으로 CloudKit이 nil인지 재확인)
// ─────────────────────────────────────────────────────────────────
static void (*orig_loadPersistentStores)(id, SEL, void (^)(NSPersistentStoreDescription *, NSError *)) = NULL;
static void hook_loadPersistentStores(id self, SEL _cmd, void (^block)(NSPersistentStoreDescription *, NSError *)) {
    LOG("loadPersistentStoresWithCompletionHandler: 호출됨 -> 로컬 스토어로 강제");
    neutralize_store_descriptions(self, "pre-loadStores");
    if (orig_loadPersistentStores) {
        orig_loadPersistentStores(self, _cmd, block);
    }
}

// ─────────────────────────────────────────────────────────────────
// 5. NSUbiquitousKeyValueStore 동기화 방어 (선택적)
// ─────────────────────────────────────────────────────────────────
static BOOL (*orig_kv_synchronize)(id, SEL) = NULL;
static BOOL hook_kv_synchronize(id self, SEL _cmd) {
    LOG("NSUbiquitousKeyValueStore synchronize 차단");
    return NO;
}

// ─────────────────────────────────────────────────────────────────
// 생성자: dylib 로드 시 1회 실행
// ─────────────────────────────────────────────────────────────────
__attribute__((constructor))
static void GNCloudKitFix_initialize(void) {
    LOG("══════════════════════════════════════════════════");
    LOG("  Goodnotes 7.1.19 CloudKit Fix (v2.0 Safe) 로드  ");
    LOG("══════════════════════════════════════════════════");

    // CoreData 프레임워크 강제 로드
    dlopen("/System/Library/Frameworks/CoreData.framework/CoreData", RTLD_NOW | RTLD_GLOBAL);

    // [1] NSPersistentStoreDescription 후킹
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
    } else {
        LOG("⚠️ NSPersistentStoreDescription 클래스를 찾을 수 없습니다.");
    }

    // [2] NSPersistentCloudKitContainer 후킹
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
    } else {
        LOG("⚠️ NSPersistentCloudKitContainer 클래스를 찾을 수 없습니다.");
    }

    // [3] NSUbiquitousKeyValueStore synchronize 후킹 (iCloud KV 스토어 에러 방지)
    Class kvClass = objc_getClass("NSUbiquitousKeyValueStore");
    if (kvClass) {
        safe_swizzle_instance(kvClass,
            @selector(synchronize),
            (IMP)hook_kv_synchronize,
            (IMP*)&orig_kv_synchronize);
    }

    LOG("══════════════════════════════════════════════════");
    LOG("  GNCloudKitFix 초기화 완료 (Safe Mode Active)     ");
    LOG("══════════════════════════════════════════════════");
}