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
"    }\n"
"  },\n"
"  \"subscriptions\": {\n"
"    \"com.goodnotes.gn6_one_time_unlock_3999\": {\n"
"      \"expiresDateMs\": 4102444800000,\n"
"      \"planKey\": \"pro\"\n"
"    }\n"
"  },\n"
"  \"nonSubscriptions\": {},\n"
"  \"currentPlans\": {\n"
"    \"base\": {\n"
"      \"productIdentifier\": \"com.goodnotes.gn6_one_time_unlock_3999\",\n"
"      \"planKey\": \"pro\"\n"
"    }\n"
"  },\n"
"  \"entitlementVerification\": \"NOT_REQUESTED\"\n"
"}";

static id (*orig_dataTaskWithRequest_completionHandler)(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error));

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

static id swizzled_dataTaskWithRequest_completionHandler(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error)) {
    NSURL *url = request.URL;
    if (shouldInterceptURL(url) && completionHandler) {
        NSLog(@"[GN7RevenueCatFix] Intercepting request to: %@", url);
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

__attribute__((constructor))
static void GN7RevenueCatFixInit(void) {
    NSLog(@"[GN7RevenueCatFix] Initializing Goodnotes 7 RevenueCat & Entitlement Hook...");
    
    Class sessionClass = [NSURLSession class];
    SEL sel = @selector(dataTaskWithRequest:completionHandler:);
    Method method = class_getInstanceMethod(sessionClass, sel);
    
    if (method) {
        orig_dataTaskWithRequest_completionHandler = (void *)method_getImplementation(method);
        method_setImplementation(method, (IMP)swizzled_dataTaskWithRequest_completionHandler);
        NSLog(@"[GN7RevenueCatFix] Successfully swizzled -[NSURLSession dataTaskWithRequest:completionHandler:]");
    } else {
        NSLog(@"[GN7RevenueCatFix] Warning: Could not find method -[NSURLSession dataTaskWithRequest:completionHandler:]");
    }
}
