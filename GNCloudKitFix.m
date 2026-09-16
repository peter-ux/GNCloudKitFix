/*
 * GNCloudKitFix.dylib
 * ───────────────────────────────────────────────────────────────────
 * Goodnotes 7.1.19 iCloud 크래시 수정 dylib
 *
 * 전략:
 *   1) NSPersistentCloudKitContainer의 initWithName:managedObjectModel: 후킹
 *      → loadPersistentStores 전에 cloudKitContainerOptions = nil 설정
 *      → CloudKit 동기화 비활성화하여 로컬 전용 컨테이너로 동작
 *   2) +alloc 은 건드리지 않음 (Swift 내부 초기화 체인 보호)
 *   3) CKContainer 접근 차단 (CloudKit sync 시도 방지)
 *   4) NSUbiquitousKeyValueStore 동기화 차단
 *   5) NSCloudKitMirroringDelegate 에러 핸들링
 *
 * 빌드 (GitHub Actions / Mac):
 *   clang -dynamiclib \
 *     -framework Foundation \
 *     -framework CoreData \
 *     -framework CloudKit \
 *     -lobjc \
 *     -arch arm64 \
 *     -miphoneos-version-min=15.0 \
 *     -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
 *     -o GNCloudKitFix.dylib GNCloudKitFix.m
 * ───────────────────────────────────────────────────────────────────
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CloudKit/CloudKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <dlfcn.h>

// ─────────────────────────────────────────
// 1. NSPersistentCloudKitContainer 초기화 후킹
// ─────────────────────────────────────────
//
// 핵심 전략: initWithName:managedObjectModel: 를 후킹하여
// 원본 init을 호출한 뒤 → 모든 persistentStoreDescription의
// cloudKitContainerOptions를 nil로 설정.
// 이렇게 하면 loadPersistentStores가 CloudKit을 사용하지 않고
// 로컬 Core Data 스토어로만 동작.

static IMP original_initWithName_managedObjectModel = NULL;
static IMP original_initWithName = NULL;

// initWithName:managedObjectModel: 후킹
static id hooked_initWithName_managedObjectModel(id self, SEL _cmd, NSString *name, NSManagedObjectModel *model) {
    NSLog(@"[GNCloudKitFix] initWithName:managedObjectModel: 가로챔 - name=%@", name);

    // 원본 init 호출 (컨테이너 정상 생성)
    id result = ((id(*)(id, SEL, NSString*, NSManagedObjectModel*))original_initWithName_managedObjectModel)(self, _cmd, name, model);

    if (result) {
        // 모든 persistentStoreDescription의 CloudKit 옵션 제거
        NSArray *descriptions = [result performSelector:@selector(persistentStoreDescriptions)];
        for (NSPersistentStoreDescription *desc in descriptions) {
            if ([desc respondsToSelector:@selector(setCloudKitContainerOptions:)]) {
                [desc performSelector:@selector(setCloudKitContainerOptions:) withObject:nil];
                NSLog(@"[GNCloudKitFix] cloudKitContainerOptions = nil 설정 완료 (URL: %@)", desc.URL);
            }
        }
        NSLog(@"[GNCloudKitFix] 컨테이너 '%@' → 로컬 전용 모드로 전환 완료", name);
    }

    return result;
}

// initWithName: 후킹 (managedObjectModel 없는 convenience init)
static id hooked_initWithName(id self, SEL _cmd, NSString *name) {
    NSLog(@"[GNCloudKitFix] initWithName: 가로챔 - name=%@", name);

    // 원본 init 호출
    id result = ((id(*)(id, SEL, NSString*))original_initWithName)(self, _cmd, name);

    if (result) {
        NSArray *descriptions = [result performSelector:@selector(persistentStoreDescriptions)];
        for (NSPersistentStoreDescription *desc in descriptions) {
            if ([desc respondsToSelector:@selector(setCloudKitContainerOptions:)]) {
                [desc performSelector:@selector(setCloudKitContainerOptions:) withObject:nil];
                NSLog(@"[GNCloudKitFix] cloudKitContainerOptions = nil 설정 완료");
            }
        }
        NSLog(@"[GNCloudKitFix] 컨테이너 '%@' → 로컬 전용 모드로 전환 완료", name);
    }

    return result;
}


// ─────────────────────────────────────────
// 2. CKContainer 차단
// ─────────────────────────────────────────
// CloudKit sync 관련 코드가 CKContainer에 접근하는 것을 차단

@interface CKContainer (GNFix)
+ (id)gn_defaultContainer;
+ (id)gn_containerWithIdentifier:(NSString *)containerIdentifier;
@end

@implementation CKContainer (GNFix)

+ (id)gn_defaultContainer {
    NSLog(@"[GNCloudKitFix] CKContainer.defaultContainer() 차단 → nil");
    return nil;
}

+ (id)gn_containerWithIdentifier:(NSString *)containerIdentifier {
    NSLog(@"[GNCloudKitFix] CKContainer.containerWithIdentifier(%@) 차단 → nil", containerIdentifier);
    return nil;
}

@end


// ─────────────────────────────────────────
// 3. NSUbiquitousKeyValueStore 차단
// ─────────────────────────────────────────
// iCloud KV Store 동기화 차단 (entitlement 없으면 크래시)

@interface NSUbiquitousKeyValueStore (GNFix)
+ (id)gn_defaultStore;
- (BOOL)gn_synchronize;
@end

@implementation NSUbiquitousKeyValueStore (GNFix)

+ (id)gn_defaultStore {
    NSLog(@"[GNCloudKitFix] NSUbiquitousKeyValueStore.defaultStore 차단 → nil");
    return nil;
}

- (BOOL)gn_synchronize {
    NSLog(@"[GNCloudKitFix] NSUbiquitousKeyValueStore.synchronize 차단");
    return NO;
}

@end


// ─────────────────────────────────────────
// 4. NSCloudKitMirroringDelegate 에러 방지
// ─────────────────────────────────────────
// 혹시 CloudKit 미러링 델리게이트가 생성되더라도 에러를 방지

static IMP original_mirroringDelegate_init = NULL;

static id hooked_mirroringDelegate_init(id self, SEL _cmd) {
    NSLog(@"[GNCloudKitFix] NSCloudKitMirroringDelegate init 차단 → nil");
    return nil;
}


// ─────────────────────────────────────────
// 스위즐링 헬퍼
// ─────────────────────────────────────────

static void swizzle_class_method(Class cls, SEL original, SEL replacement) {
    Method orig = class_getClassMethod(cls, original);
    Method repl = class_getClassMethod(cls, replacement);
    if (orig && repl) {
        method_exchangeImplementations(orig, repl);
        NSLog(@"[GNCloudKitFix] 스위즐 성공: +[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(original));
    } else {
        NSLog(@"[GNCloudKitFix] 스위즐 실패: +[%@ %@] (orig=%p repl=%p)",
              NSStringFromClass(cls), NSStringFromSelector(original), orig, repl);
    }
}

static void swizzle_instance_method(Class cls, SEL original, SEL replacement) {
    Method orig = class_getInstanceMethod(cls, original);
    Method repl = class_getInstanceMethod(cls, replacement);
    if (orig && repl) {
        method_exchangeImplementations(orig, repl);
        NSLog(@"[GNCloudKitFix] 스위즐 성공: -[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(original));
    } else {
        NSLog(@"[GNCloudKitFix] 스위즐 실패: -[%@ %@] (orig=%p repl=%p)",
              NSStringFromClass(cls), NSStringFromSelector(original), orig, repl);
    }
}

static void replace_instance_method(Class cls, SEL selector, IMP newIMP, IMP *outOriginal) {
    Method m = class_getInstanceMethod(cls, selector);
    if (m) {
        *outOriginal = method_setImplementation(m, newIMP);
        NSLog(@"[GNCloudKitFix] IMP 교체 성공: -[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(selector));
    } else {
        NSLog(@"[GNCloudKitFix] IMP 교체 실패: -[%@ %@] (메서드 없음)",
              NSStringFromClass(cls), NSStringFromSelector(selector));
    }
}


// ─────────────────────────────────────────
// 생성자: dylib 로드 시 자동 실행
// ─────────────────────────────────────────

__attribute__((constructor))
static void GNCloudKitFix_init(void) {
    NSLog(@"[GNCloudKitFix] ═══════════════════════════════════════");
    NSLog(@"[GNCloudKitFix] Goodnotes 7.x iCloud 크래시 수정 로드됨");
    NSLog(@"[GNCloudKitFix] ═══════════════════════════════════════");

    // CoreData 프레임워크 확실히 로드
    dlopen("/System/Library/Frameworks/CoreData.framework/CoreData", RTLD_NOW | RTLD_GLOBAL);
    dlopen("/System/Library/Frameworks/CloudKit.framework/CloudKit", RTLD_NOW | RTLD_GLOBAL);

    // ──── 1. NSPersistentCloudKitContainer init 후킹 ────
    Class ckContainerClass = objc_getClass("NSPersistentCloudKitContainer");
    if (ckContainerClass) {
        // initWithName:managedObjectModel: 후킹 (IMP 직접 교체)
        replace_instance_method(ckContainerClass,
            @selector(initWithName:managedObjectModel:),
            (IMP)hooked_initWithName_managedObjectModel,
            &original_initWithName_managedObjectModel);

        // initWithName: 후킹
        replace_instance_method(ckContainerClass,
            @selector(initWithName:),
            (IMP)hooked_initWithName,
            &original_initWithName);

        NSLog(@"[GNCloudKitFix] NSPersistentCloudKitContainer 초기화 후킹 완료");
    } else {
        NSLog(@"[GNCloudKitFix] ⚠️ NSPersistentCloudKitContainer 클래스 없음");
    }

    // ──── 2. CKContainer 차단 ────
    Class ckClass = objc_getClass("CKContainer");
    if (ckClass) {
        swizzle_class_method(ckClass,
            @selector(defaultContainer),
            @selector(gn_defaultContainer));

        swizzle_class_method(ckClass,
            @selector(containerWithIdentifier:),
            @selector(gn_containerWithIdentifier:));

        NSLog(@"[GNCloudKitFix] CKContainer 차단 완료");
    }

    // ──── 3. NSUbiquitousKeyValueStore 차단 ────
    Class kvClass = objc_getClass("NSUbiquitousKeyValueStore");
    if (kvClass) {
        swizzle_class_method(kvClass,
            @selector(defaultStore),
            @selector(gn_defaultStore));

        swizzle_instance_method(kvClass,
            @selector(synchronize),
            @selector(gn_synchronize));

        NSLog(@"[GNCloudKitFix] NSUbiquitousKeyValueStore 차단 완료");
    }

    // ──── 4. NSCloudKitMirroringDelegate 차단 ────
    Class mirrorClass = objc_getClass("NSCloudKitMirroringDelegate");
    if (mirrorClass) {
        replace_instance_method(mirrorClass,
            @selector(init),
            (IMP)hooked_mirroringDelegate_init,
            &original_mirroringDelegate_init);
        NSLog(@"[GNCloudKitFix] NSCloudKitMirroringDelegate 차단 완료");
    }

    NSLog(@"[GNCloudKitFix] ═══════════════════════════════════════");
    NSLog(@"[GNCloudKitFix] 초기화 완료 — 로컬 전용 모드");
    NSLog(@"[GNCloudKitFix] ═══════════════════════════════════════");
}