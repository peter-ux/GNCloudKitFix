#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <objc/runtime.h>
#import <objc/message.h>


static void swizzle_class_method(Class cls, SEL original, SEL replacement) {
    Method orig = class_getClassMethod(cls, original);
    Method repl = class_getClassMethod(cls, replacement);
    if (orig && repl) {
        method_exchangeImplementations(orig, repl);
        NSLog(@"[GNCloudKitFix] swizzled +[%@ %@]",
              NSStringFromClass(cls), NSStringFromSelector(original));
    } else {
        NSLog(@"[GNCloudKitFix] swizzle 실패: +[%@ %@] orig=%p repl=%p",
              NSStringFromClass(cls), NSStringFromSelector(original),
              (void*)orig, (void*)repl);
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


/*
 * NSPersistentCloudKitContainer는 NSPersistentContainer의 서브클래스.
 * +alloc 을 후킹해서 NSPersistentContainer 인스턴스를 반환하면
 * 이후 -initWithName: 등 모든 초기화가 로컬 Container 기준으로 동작.
 */

@interface NSPersistentCloudKitContainer (GNFix)
+ (instancetype)gn_alloc;
- (instancetype)gn_initWithName:(NSString *)name;
- (instancetype)gn_initWithName:(NSString *)name
             managedObjectModel:(NSManagedObjectModel *)model;
@end

@implementation NSPersistentCloudKitContainer (GNFix)

// +alloc 후킹: NSPersistentContainer 인스턴스 반환
+ (instancetype)gn_alloc {
    NSLog(@"[GNCloudKitFix] +[NSPersistentCloudKitContainer alloc] 가로챔 → NSPersistentContainer 반환");
    return [NSPersistentContainer alloc];
}

// -initWithName: 후킹 (혹시 직접 호출되는 경우 대비)
- (instancetype)gn_initWithName:(NSString *)name {
    NSLog(@"[GNCloudKitFix] -initWithName:%@ 가로챔", name);
    // self가 이미 NSPersistentContainer이므로 직접 호출
    return [self gn_initWithName:name]; // 원본 호출 (교환됐으므로 원본)
}

- (instancetype)gn_initWithName:(NSString *)name
             managedObjectModel:(NSManagedObjectModel *)model {
    NSLog(@"[GNCloudKitFix] -initWithName:%@ managedObjectModel: 가로챔", name);
    return [self gn_initWithName:name managedObjectModel:model];
}

@end

// ─────────────────────────────────────────
// CKContainer.default() 스위즐링 (보조)
// ─────────────────────────────────────────

/*
 * CloudKitSyncStoreV2가 CKContainer.default()를 직접 호출.
 * nil을 반환하거나 더미 컨테이너를 반환해서 CloudKit 연결 시도를 막음.
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@interface CKContainer (GNFix)
+ (CKContainer *)gn_defaultContainer;
@end

@implementation CKContainer (GNFix)

+ (CKContainer *)gn_defaultContainer {
    NSLog(@"[GNCloudKitFix] CKContainer.default() 차단");
    // nil 반환: CloudKitSyncStoreV2가 nil 체크 후 graceful degradation
    return nil;
}

@end

#pragma clang diagnostic pop

// ─────────────────────────────────────────
// NSUbiquitousKeyValueStore 스위즐링 (보조)
// ─────────────────────────────────────────

@interface NSUbiquitousKeyValueStore (GNFix)
- (BOOL)gn_synchronize;
@end

@implementation NSUbiquitousKeyValueStore (GNFix)

- (BOOL)gn_synchronize {
    // iCloud KV Store 동기화 시도 차단 (entitlement 없으면 크래시)
    NSLog(@"[GNCloudKitFix] NSUbiquitousKeyValueStore synchronize 차단");
    return NO;
}

@end

// ─────────────────────────────────────────
// 생성자: dylib 로드 시 자동 실행
// ─────────────────────────────────────────

__attribute__((constructor))
static void GNCloudKitFix_init(void) {
    NSLog(@"[GNCloudKitFix] 로드 — Goodnotes 7.x iCloud 크래시 수정");

    // 1. NSPersistentCloudKitContainer → NSPersistentContainer 교체
    Class ckContainerClass = objc_getClass("NSPersistentCloudKitContainer");
    if (ckContainerClass) {
        swizzle_class_method(
            ckContainerClass,
            @selector(alloc),
            @selector(gn_alloc)
        );
        NSLog(@"[GNCloudKitFix] NSPersistentCloudKitContainer 스위즐링 완료");
    } else {
        // Swift 정적 링크된 경우 objc_getClass로 못 찾을 수 있음
        // 이 경우 CoreData.framework를 직접 로드
        NSLog(@"[GNCloudKitFix]  NSPersistentCloudKitContainer 클래스 없음 — CoreData 직접 로드 시도");
        void *handle = dlopen("/System/Library/Frameworks/CoreData.framework/CoreData", RTLD_NOW);
        if (handle) {
            ckContainerClass = objc_getClass("NSPersistentCloudKitContainer");
            if (ckContainerClass) {
                swizzle_class_method(
                    ckContainerClass,
                    @selector(alloc),
                    @selector(gn_alloc)
                );
                NSLog(@"[GNCloudKitFix] CoreData 직접 로드 후 스위즐링 완료");
            }
        }
    }

    // 2. CKContainer.default() 차단
    Class ckClass = objc_getClass("CKContainer");
    if (ckClass) {
        swizzle_class_method(
            ckClass,
            @selector(defaultContainer),
            @selector(gn_defaultContainer)
        );
    }

    // 3. NSUbiquitousKeyValueStore.synchronize() 차단
    Class kvStore = objc_getClass("NSUbiquitousKeyValueStore");
    if (kvStore) {
        swizzle_instance_method(
            kvStore,
            @selector(synchronize),
            @selector(gn_synchronize)
        );
    }

    NSLog(@"[GNCloudKitFix] 초기화 완료");
}
