#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kGN7MockCustomerInfoJSON = @"{\n"
"  \"request_date\": \"2026-09-22T00:00:00Z\",\n"
"  \"request_date_ms\": 1790000000000,\n"
"  \"subscriber\": {\n"
"    \"original_app_user_id\": \"gn7_pro_user\",\n"
"    \"original_application_version\": \"7.1.19\",\n"
"    \"original_purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"    \"management_url\": null,\n"
"    \"entitlements\": {\n"
"      \"apple_access\": {\n"
"        \"expires_date\": null,\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"pro_access\": {\n"
"        \"expires_date\": null,\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"gnc_access\": {\n"
"        \"expires_date\": null,\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"crossplatform_access\": {\n"
"        \"expires_date\": null,\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"full_access\": {\n"
"        \"expires_date\": null,\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      }\n"
"    },\n"
"    \"subscriptions\": {\n"
"      \"com.goodnotes.pro_promotional\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"original_purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"        \"store\": \"app_store\",\n"
"        \"ownership_type\": \"PURCHASED\",\n"
"        \"is_sandbox\": false\n"
"      }\n"
"    },\n"
"    \"non_subscriptions\": {\n"
"      \"com.goodnotes.gn6_one_time_unlock_3999\": [\n"
"        {\n"
"          \"id\": \"gn7_onetime_tx_001\",\n"
"          \"original_purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"          \"purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"          \"store\": \"app_store\"\n"
"        }\n"
"      ]\n"
"    },\n"
"    \"other_purchases\": {}\n"
"  },\n"
"  \"email\": \"pro@goodnotes.com\",\n"
"  \"email_verified\": true,\n"
"  \"entitlements\": {\n"
"    \"apple_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": null,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"pro_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": null,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"gnc_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": null,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"crossplatform_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": null,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"full_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": null,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    }\n"
"  },\n"
"  \"subscriptions\": {\n"
"    \"com.goodnotes.pro_promotional\": {\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"planKey\": \"pro\"\n"
"    }\n"
"  },\n"
"  \"nonSubscriptions\": {\n"
"    \"com.goodnotes.gn6_one_time_unlock_3999\": [\n"
"      {\n"
"        \"id\": \"gn7_onetime_tx_001\",\n"
"        \"originalPurchaseDateMs\": 1600000000000,\n"
"        \"purchaseDateMs\": 1600000000000\n"
"      }\n"
"    ]\n"
"  },\n"
"  \"currentPlans\": {\n"
"    \"base\": {\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"planKey\": \"pro\"\n"
"    },\n"
"    \"ai\": {\n"
"      \"productIdentifier\": \"com.goodnotes.plus.ai.premium_7dt_1y_2999\",\n"
"      \"planKey\": \"premium\"\n"
"    }\n"
"  },\n"
"  \"entitlementVerification\": \"NOT_REQUESTED\"\n"
"}";

static BOOL shouldInterceptURL(NSURL *url) {
    if (!url) return NO;
    NSString *urlString = [url absoluteString].lowercaseString;
    if ([urlString containsString:@"revenuecat.com"] ||
        [urlString containsString:@"/v1/subscribers"] ||
        [urlString containsString:@"/v3/subscribers"] ||
        [urlString containsString:@"/offerings"] ||
        [urlString containsString:@"goodnotes.com/nest/api"] ||
        [urlString containsString:@"purchases"]) {
        return YES;
    }
    return NO;
}

@interface GN7URLProtocol : NSURLProtocol
@end

@implementation GN7URLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:@"GN7URLProtocolHandled" inRequest:request]) {
        return NO;
    }
    return shouldInterceptURL(request.URL);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"GN7URLProtocolHandled" inRequest:newRequest];
    
    NSLog(@"[GN7URLProtocol] Intercepted URL: %@", self.request.URL);
    
    NSData *mockData = [kGN7MockCustomerInfoJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{
                                                                @"Content-Type": @"application/json",
                                                                @"X-RevenueCat-ETag": @"gn7_mock_etag_2026"
                                                            }];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:mockData];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end

// ─────────────────────────────────────────────────────────────────
// NSURLSessionConfiguration 스위즐링 — Thread-Safe (v8.7)
// RevenueCat SDK는 ephemeral 세션을 사용하므로
// NSURLProtocol.registerClass만으로는 인터셉트 불가.
// @synchronized + immutable copy로 thread-safety 보장.
// ─────────────────────────────────────────────────────────────────
static NSURLSessionConfiguration *(*orig_defaultSessionConfiguration)(id self, SEL _cmd);
static NSURLSessionConfiguration *(*orig_ephemeralSessionConfiguration)(id self, SEL _cmd);

static NSURLSessionConfiguration *swizzled_defaultSessionConfiguration(id self, SEL _cmd) {
    NSURLSessionConfiguration *config = orig_defaultSessionConfiguration(self, _cmd);
    @synchronized([GN7URLProtocol class]) {
        NSArray *existing = config.protocolClasses;
        if (![existing containsObject:[GN7URLProtocol class]]) {
            NSMutableArray *protocols = existing ? [existing mutableCopy] : [NSMutableArray array];
            [protocols insertObject:[GN7URLProtocol class] atIndex:0];
            config.protocolClasses = [protocols copy]; // immutable copy for thread safety
        }
    }
    return config;
}

static NSURLSessionConfiguration *swizzled_ephemeralSessionConfiguration(id self, SEL _cmd) {
    NSURLSessionConfiguration *config = orig_ephemeralSessionConfiguration(self, _cmd);
    @synchronized([GN7URLProtocol class]) {
        NSArray *existing = config.protocolClasses;
        if (![existing containsObject:[GN7URLProtocol class]]) {
            NSMutableArray *protocols = existing ? [existing mutableCopy] : [NSMutableArray array];
            [protocols insertObject:[GN7URLProtocol class] atIndex:0];
            config.protocolClasses = [protocols copy];
        }
    }
    return config;
}

__attribute__((constructor))
static void GN7RevenueCatFixInit(void) {
    NSLog(@"[GN7RevenueCatFix] Initializing v8.7 (Thread-Safe Session Interception)...");
    
    // Register custom NSURLProtocol for shared/default sessions
    [NSURLProtocol registerClass:[GN7URLProtocol class]];
    NSLog(@"[GN7RevenueCatFix] Registered GN7URLProtocol.");
    
    // Swizzle NSURLSessionConfiguration for ephemeral sessions (RevenueCat)
    Method defaultMethod = class_getClassMethod(
        objc_getClass("NSURLSessionConfiguration"), @selector(defaultSessionConfiguration));
    Method ephemeralMethod = class_getClassMethod(
        objc_getClass("NSURLSessionConfiguration"), @selector(ephemeralSessionConfiguration));
    
    if (defaultMethod) {
        orig_defaultSessionConfiguration = (void *)method_getImplementation(defaultMethod);
        method_setImplementation(defaultMethod, (IMP)swizzled_defaultSessionConfiguration);
        NSLog(@"[GN7RevenueCatFix] Swizzled defaultSessionConfiguration");
    }
    
    if (ephemeralMethod) {
        orig_ephemeralSessionConfiguration = (void *)method_getImplementation(ephemeralMethod);
        method_setImplementation(ephemeralMethod, (IMP)swizzled_ephemeralSessionConfiguration);
        NSLog(@"[GN7RevenueCatFix] Swizzled ephemeralSessionConfiguration");
    }
    
    NSLog(@"[GN7RevenueCatFix] v8.7 initialization complete.");
}
