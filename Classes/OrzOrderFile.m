//
//  OrzOrderFile.m
//  OrzOrderFile
//
//  Created by joker on 2021/10/23.
//

#import "OrzOrderFile.h"
#import <UIKit/UIKit.h>
#import "OrzClang.h"

@interface OrzOrderFile()
@property (nonatomic, strong) dispatch_queue_t writeOrderFileQueue;
@end
@implementation OrzOrderFile
+ (void)stopRecordOrderFileSymbolsWithCompletion:(void (^)(NSString * _Nullable))completion {
    if(!isStopRecordOrderFileSymbols) {
        isStopRecordOrderFileSymbols = YES;
        NSLog(@"OrzOrderFile: 停止收集符号");
        dispatch_async([OrzOrderFile shared].writeOrderFileQueue, ^{
            NSString *orderFilePath = [OrzOrderFile writeToFileWithSymbols:getOrderFileSymbols()];
            if(completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(orderFilePath);
                });
            }
        });
    }
    else {
        if(completion) {
            NSString *orderFilePath = [OrzOrderFile orderFilePath];
            if([[NSFileManager defaultManager] fileExistsAtPath:orderFilePath]) {
                completion(orderFilePath);
            } else {
                completion(nil);
            }
        }
    }
}
+ (NSString *)writeToFileWithSymbols:(NSArray *)symbols {
    if(symbols.count <= 0) {
        return nil;
    }
    NSString *orderFilePath = [OrzOrderFile orderFilePath];
    NSString *orderFileContent = [symbols componentsJoinedByString:@"\n"];
    NSError *error = nil;
    [orderFileContent writeToFile:orderFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"OrzOrderFile: 写入文件(%@)", !error ? @"成功" : @"失败");
    NSLog(@"OrzOrderFile: OrderFilePath = %@", orderFilePath);
    return error ? nil : orderFilePath;
}
+ (NSString *)orderFileContentWithFilePath:(NSString *)orderFilePath {
    if([[NSFileManager defaultManager] fileExistsAtPath:orderFilePath]) {
        return [NSString stringWithContentsOfFile:orderFilePath encoding:NSUTF8StringEncoding error:nil];
    }
    return nil;
}
+ (void)shareByAirDropWithOrderFilePath:(NSString *)orderFilePath {
    if(!orderFilePath || ![[NSFileManager defaultManager] fileExistsAtPath:orderFilePath]) {
        NSLog(@"OrzOrderFile: 无效OrderFile文件路径！");
        return;
    }
    UIViewController *currentVC = [OrzOrderFile getCurrentVC];
    if(![currentVC isKindOfClass:UIActivityViewController.class]) {
        NSURL *url = [NSURL fileURLWithPath:orderFilePath];
        NSArray *objectsToShare = @[url];
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
        controller.excludedActivityTypes = @[
            UIActivityTypePostToTwitter,
            UIActivityTypePostToFacebook,
            UIActivityTypePostToWeibo,
            UIActivityTypeMessage,
            UIActivityTypeMail,
            UIActivityTypePrint,
            UIActivityTypeCopyToPasteboard,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo,
            UIActivityTypePostToTencentWeibo,
        ];
        [currentVC presentViewController:controller animated:YES completion:nil];
    }
}
#pragma mark - 私有方法
- (dispatch_queue_t)writeOrderFileQueue {
    if(!_writeOrderFileQueue) {
        _writeOrderFileQueue = dispatch_queue_create("com.orz.order.file.write.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _writeOrderFileQueue;
}
+ (NSString *)orderFilePath {
    NSString *lastPathComponent = [NSBundle bundleForClass:self].bundlePath.lastPathComponent;
    NSString *splitChar = @".";
    NSString *txtExt = @"txt";
    NSString *orderFileName = [@[[lastPathComponent componentsSeparatedByString:splitChar].firstObject, txtExt] componentsJoinedByString:splitChar];
    if(!orderFileName) {
        return nil;
    }
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *orderFilePath = [docDir stringByAppendingPathComponent:orderFileName];
    return orderFilePath;
}
+ (UIViewController *)getCurrentVC{
    //app默认windowLevel是UIWindowLevelNormal，如果不是，找到UIWindowLevelNormal的
    //其他框架可能会改我们的keywindow，比如支付宝支付，qq登录都是在一个新的window上，这时候的keywindow就不是appdelegate中的window。 当然这里也可以直接用APPdelegate里的window。
    __block UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(__kindof UIWindow * _Nonnull win, NSUInteger idx, BOOL * _Nonnull stop) {
            if (win.windowLevel == UIWindowLevelNormal) {
                window = win;
                *stop = YES;
            }
        }];
    }
    UIViewController* currentViewController = window.rootViewController;
    while (YES) {
        if (currentViewController.presentedViewController) {
            currentViewController = currentViewController.presentedViewController;
        }
        else {
            if ([currentViewController isKindOfClass:[UINavigationController class]]) {
                currentViewController = ((UINavigationController *)currentViewController).visibleViewController;
            } else if ([currentViewController isKindOfClass:[UITabBarController class]]) {
                currentViewController = ((UITabBarController* )currentViewController).selectedViewController;
            } else {
                break;
            }
        }
    }
    return currentViewController;
}
+ (void)setup {
    [OrzOrderFile shared];
}
#pragma mark - 单例
+ (instancetype)shared {
    static OrzOrderFile *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[OrzOrderFile alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidLaunchFinished:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    }
    return self;
}

- (void)appDidLaunchFinished:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceProximityStateChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    });
}
- (void)deviceProximityStateChange:(NSNotification *)notification {
    [OrzOrderFile stopRecordOrderFileSymbolsWithCompletion:^(NSString * _Nullable orderFilePath) {
        [OrzOrderFile shareByAirDropWithOrderFilePath:orderFilePath];
    }];
}
@end
