/*
 * GNCloudKitFix.dylib
 * ───────────────────────────────────────────────────────────────────
 * Goodnotes 7.1.19 iCloud 크래시 수정 dylib
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
// 스위즐링 헬퍼
// ─────────────────────────────────────────

static void swizzle_class_method(Class cls, SEL original, SEL replacement) {
    Method orig = class_getClassMethod(cls, original);
    Method repl = class_getClassMethod(cls, replacement);
    if (orig && repl) {
        method_exchangeImplementations(orig, repl);
        NSLog(@"[GNCloudKitFix] swizzled +[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(original));
    } else {
        NSLog(@"[GNCloudKitFix] swizzle 실패: +[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(original));
    }
}

static void swizzle_instance_method(Class cls, SEL original, SEL replacement) {
    Method orig = class_getInstanceMethod(cls, original);
    Method repl = class_getInstanceMethod(cls, replacement);
    if (orig && repl) {
        method_exchangeImplementations(orig, repl);
        NSLog(@"[GNCloudKitFix] swizzled -[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(original));
    }
}

// ─────────────────────────────────────────
// NSPersistentCloudKitContainer 스위즐링
// ─────────────────────────────────────────
//
// +alloc 을 후킹해서 NSPersistentContainer 인스턴스를 반환.
// instancetype 경고를 피하기 위해 id 반환 타입 사용.

@interface NSPersistentCloudKitContainer (GNFix)
+ (id)gn_alloc;
@end

@implementation NSPersistentCloudKitContainer (GNFix)

+ (id)gn_alloc {
    NSLog(@"[GNCloudKitFix] NSPersistentCloudKitContainer +alloc 가로챔 -> NSPersistentContainer 반환");
    return [NSPersistentContainer alloc];
}

@end

// ─────────────────────────────────────────
// CKContainer 스위즐링
// ─────────────────────────────────────────
//
// CloudKitSyncStoreV2가 CKContainer.default()를 호출.
// nil 반환으로 CloudKit 연결 시도를 차단.

@interface CKContainer (GNFix)
+ (id)gn_defaultContainer;
@end

@implementation CKContainer (GNFix)

+ (id)gn_defaultContainer {
    NSLog(@"[GNCloudKitFix] CKContainer.default() 차단 -> nil 반환");
    return nil;
}

@end

// ─────────────────────────────────────────
// NSUbiquitousKeyValueStore 스위즐링
// ─────────────────────────────────────────
//
// iCloud KV Store 동기화 차단 (entitlement 없으면 크래시).

@interface NSUbiquitousKeyValueStore (GNFix)
- (BOOL)gn_synchronize;
@end

@implementation NSUbiquitousKeyValueStore (GNFix)

- (BOOL)gn_synchronize {
    NSLog(@"[GNCloudKitFix] NSUbiquitousKeyValueStore synchronize 차단");
    return NO;
}

@end

// ─────────────────────────────────────────
// 생성자: dylib 로드 시 자동 실행
// ─────────────────────────────────────────

__attribute__((constructor))
static void GNCloudKitFix_init(void) {
    NSLog(@"[GNCloudKitFix] 로드됨 - Goodnotes 7.x iCloud 크래시 수정");

    // 1. NSPersistentCloudKitContainer -> NSPersistentContainer 교체
    Class ckContainerClass = objc_getClass("NSPersistentCloudKitContainer");
    if (!ckContainerClass) {
        // CoreData가 아직 로드 안 됐을 경우 직접 로드
        NSLog(@"[GNCloudKitFix] NSPersistentCloudKitContainer 없음 - CoreData 직접 로드");
        dlopen("/System/Library/Frameworks/CoreData.framework/CoreData", RTLD_NOW | RTLD_GLOBAL);
        ckContainerClass = objc_getClass("NSPersistentCloudKitContainer");
    }

    if (ckContainerClass) {
        // +alloc 스위즐링
        // class_getClassMethod로 메타클래스의 메서드를 교환
        Method origAlloc = class_getClassMethod(ckContainerClass, @selector(alloc));
        Method replAlloc = class_getClassMethod(ckContainerClass, @selector(gn_alloc));
        if (origAlloc && replAlloc) {
            method_exchangeImplementations(origAlloc, replAlloc);
            NSLog(@"[GNCloudKitFix] NSPersistentCloudKitContainer +alloc 스위즐링 완료");
        }
    } else {
        NSLog(@"[GNCloudKitFix] NSPersistentCloudKitContainer 클래스 없음 - 스위즐링 생략");
    }

    // 2. CKContainer.default() 차단
    Class ckClass = objc_getClass("CKContainer");
    if (ckClass) {
        Method origDefault = class_getClassMethod(ckClass, @selector(defaultContainer));
        Method replDefault = class_getClassMethod(ckClass, @selector(gn_defaultContainer));
        if (origDefault && replDefault) {
            method_exchangeImplementations(origDefault, replDefault);
            NSLog(@"[GNCloudKitFix] CKContainer.default() 스위즐링 완료");
        }
    }

    // 3. NSUbiquitousKeyValueStore.synchronize() 차단
    Class kvClass = objc_getClass("NSUbiquitousKeyValueStore");
    if (kvClass) {
        swizzle_instance_method(kvClass,
            @selector(synchronize),
            @selector(gn_synchronize));
    }

    NSLog(@"[GNCloudKitFix] 초기화 완료");
}