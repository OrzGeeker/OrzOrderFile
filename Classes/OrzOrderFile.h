//
//  OrzOrderFile.h
//  OrzOrderFile
//
//  Created by joker on 2021/10/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface OrzOrderFile : NSObject
+ (void)stopRecordOrderFileSymbolsWithCompletion:(void (^ _Nullable)(NSString * _Nullable orderFilePath))completion;
+ (NSString *)orderFileContentWithFilePath:(NSString *_Nullable)orderFilePath;
+ (void)shareByAirDropWithOrderFilePath:(NSString * _Nullable)orderFilePath;
+ (void)setup;
@end

NS_ASSUME_NONNULL_END
