//
//  OrzOrderFile.m
//  OrzOrderFile
//
//  Created by joker on 2021/10/23.
//

#import "OrzOrderFile.h"
#import <UIKit/UIKit.h>

extern BOOL isStopRecordOrderFileSymbols;
extern NSArray<NSString *>* getOrderFileSymbols(void);

@implementation OrzOrderFile
+ (void)stopRecordOrderFileSymbols {
    isStopRecordOrderFileSymbols = YES;
    [OrzOrderFile writeToFileWithSymbols:getOrderFileSymbols()];
}
+ (void)writeToFileWithSymbols:(NSArray *)symbols {
    if(symbols.count <= 0) {
        return;
    }
    NSString *orderFilePath = [OrzOrderFile orderFilePath];
    NSString *orderFileContent = [symbols componentsJoinedByString:@"\n"];
    NSError *error = nil;
    [orderFileContent writeToFile:orderFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"OrzClang: 写入文件(%@)", !error ? @"成功" : @"失败");
    NSLog(@"order file path: %@", orderFilePath);
}
+ (NSString *)orderFileContent {
    NSString *orderFilePath = [OrzOrderFile orderFilePath];
    if([[NSFileManager defaultManager] fileExistsAtPath:orderFilePath]) {
        return [NSString stringWithContentsOfFile:orderFilePath encoding:NSUTF8StringEncoding error:nil];
    }
    return nil;
}
+ (void)shareOrderFileWithAirDrop {
    NSString *orderFilePath = [OrzOrderFile orderFilePath];
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
    
    UIViewController *currentVC = [OrzOrderFile getCurrentVC];
    if(![currentVC isKindOfClass:UIActivityViewController.class]) {
        [currentVC presentViewController:controller animated:YES completion:nil];
    }
}
#pragma mark - 私有方法
+ (NSString *)orderFilePath {
    NSString *orderFile = @"order.txt";
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *orderFilePath = [docDir stringByAppendingPathComponent:orderFile];
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
    if ([UIDevice currentDevice].proximityState == YES) {
        [OrzOrderFile stopRecordOrderFileSymbols];
    } else {
        [OrzOrderFile shareOrderFileWithAirDrop];
    }
}
@end
