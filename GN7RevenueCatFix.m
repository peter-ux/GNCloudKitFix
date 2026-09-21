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
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"pro_access\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"gnc_access\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"crossplatform_access\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      },\n"
"      \"full_access\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"grace_period_expires_date\": null,\n"
"        \"product_identifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\"\n"
"      }\n"
"    },\n"
"    \"subscriptions\": {\n"
"      \"com.goodnotes.gn6_one_time_unlock_3999\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"original_purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"        \"store\": \"app_store\",\n"
"        \"ownership_type\": \"PURCHASED\",\n"
"        \"is_sandbox\": false\n"
"      },\n"
"      \"com.goodnotes.pro_promotional\": {\n"
"        \"expires_date\": \"2099-12-31T23:59:59Z\",\n"
"        \"original_purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"        \"purchase_date\": \"2023-08-09T00:00:00Z\",\n"
"        \"store\": \"app_store\",\n"
"        \"ownership_type\": \"PURCHASED\",\n"
"        \"is_sandbox\": false\n"
"      }\n"
"    },\n"
"    \"non_subscriptions\": {},\n"
"    \"other_purchases\": {}\n"
"  },\n"
"  \"email\": \"pro@goodnotes.com\",\n"
"  \"email_verified\": true,\n"
"  \"entitlements\": {\n"
"    \"apple_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"pro_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"gnc_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"crossplatform_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    },\n"
"    \"full_access\": {\n"
"      \"status\": \"active\",\n"
"      \"planKey\": \"pro\",\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"originalPurchaseDateMs\": 1600000000000,\n"
"      \"purchaseDateMs\": 1600000000000\n"
"    }\n"
"  },\n"
"  \"subscriptions\": {\n"
"    \"com.goodnotes.gn6_one_time_unlock_3999\": {\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"planKey\": \"pro\"\n"
"    },\n"
"    \"com.goodnotes.pro_promotional\": {\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"planKey\": \"pro\"\n"
"    }\n"
"  },\n"
"  \"nonSubscriptions\": {},\n"
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

static id (*orig_dataTaskWithRequest_completionHandler)(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error));

static id swizzled_dataTaskWithRequest_completionHandler(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error)) {
    NSURL *url = request.URL;
    if (shouldInterceptURL(url) && completionHandler) {
        NSLog(@"[GN7RevenueCatFix] Swizzle Intercepted request to: %@", url);
        NSData *mockData = [kGN7MockCustomerInfoJSON dataUsingEncoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *mockResponse = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                     statusCode:200
                                                                    HTTPVersion:@"HTTP/1.1"
                                                                   headerFields:@{
                                                                       @"Content-Type": @"application/json",
                                                                       @"X-RevenueCat-ETag": @"gn7_mock_etag_2026"
                                                                   }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completionHandler(mockData, mockResponse, nil);
        });
        
        return orig_dataTaskWithRequest_completionHandler(self, _cmd, [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]], ^(NSData *d, NSURLResponse *r, NSError *e){});
    }
    
    return orig_dataTaskWithRequest_completionHandler(self, _cmd, request, completionHandler);
}

static NSURLSessionConfiguration *(*orig_defaultSessionConfiguration)(id self, SEL _cmd);
static NSURLSessionConfiguration *(*orig_ephemeralSessionConfiguration)(id self, SEL _cmd);

static NSURLSessionConfiguration *swizzled_defaultSessionConfiguration(id self, SEL _cmd) {
    NSURLSessionConfiguration *config = orig_defaultSessionConfiguration(self, _cmd);
    NSMutableArray *protocols = [config.protocolClasses mutableCopy];
    if (!protocols) protocols = [NSMutableArray array];
    if (![protocols containsObject:[GN7URLProtocol class]]) {
        [protocols insertObject:[GN7URLProtocol class] atIndex:0];
        config.protocolClasses = protocols;
    }
    return config;
}

static NSURLSessionConfiguration *swizzled_ephemeralSessionConfiguration(id self, SEL _cmd) {
    NSURLSessionConfiguration *config = orig_ephemeralSessionConfiguration(self, _cmd);
    NSMutableArray *protocols = [config.protocolClasses mutableCopy];
    if (!protocols) protocols = [NSMutableArray array];
    if (![protocols containsObject:[GN7URLProtocol class]]) {
        [protocols insertObject:[GN7URLProtocol class] atIndex:0];
        config.protocolClasses = protocols;
    }
    return config;
}

__attribute__((constructor))
static void GN7RevenueCatFixInit(void) {
    NSLog(@"[GN7RevenueCatFix] Initializing Goodnotes 7 RevenueCat & Entitlement Hook v3.0...");
    
    [NSURLProtocol registerClass:[GN7URLProtocol class]];
    NSLog(@"[GN7RevenueCatFix] Registered GN7URLProtocol");

    Class configClass = [NSURLSessionConfiguration class];
    Method m_def = class_getClassMethod(configClass, @selector(defaultSessionConfiguration));
    if (m_def) {
        orig_defaultSessionConfiguration = (void *)method_getImplementation(m_def);
        method_setImplementation(m_def, (IMP)swizzled_defaultSessionConfiguration);
    }
    Method m_eph = class_getClassMethod(configClass, @selector(ephemeralSessionConfiguration));
    if (m_eph) {
        orig_ephemeralSessionConfiguration = (void *)method_getImplementation(m_eph);
        method_setImplementation(m_eph, (IMP)swizzled_ephemeralSessionConfiguration);
    }

    Class cls = NSClassFromString(@"__NSCFURLSession");
    if (!cls) cls = [NSURLSession class];
    
    SEL sel = @selector(dataTaskWithRequest:completionHandler:);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_dataTaskWithRequest_completionHandler = (void *)method_getImplementation(method);
        method_setImplementation(method, (IMP)swizzled_dataTaskWithRequest_completionHandler);
        NSLog(@"[GN7RevenueCatFix] Successfully swizzled -[%@ dataTaskWithRequest:completionHandler:]", NSStringFromClass(cls));
    }
}
