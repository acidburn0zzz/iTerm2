//
//  iTermXpcConnectionHelper.h
//  iTerm2SharedARC
//
//  Created by Benedek Kozma on 2020. 12. 23..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class iTermImage;

@interface iTermXpcConnectionHelper : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (iTermImage *_Nullable)imageFromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
