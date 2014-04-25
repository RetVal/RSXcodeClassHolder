//
//  RSXcodeClassSourceCodeGen.h
//  RSXcodeClassHolder
//
//  Created by closure on 3/21/14.
//  Copyright (c) 2014 closure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSXcodeClassSourceCodeGen : NSObject {
@private
    NSDictionary *_info;
}
+ (NSString *(^)(NSString *))defaultPropertyNameGen;
- (instancetype)initWithDictionary:(NSDictionary *)info propertyNameGenHandler:(NSString *(^)(NSString *key))propertyNameGen;
- (id)contentWithClassName:(NSString *)className;

FOUNDATION_EXPORT NSString * const RSXcodeClassSourceCodeHeaderContent;
FOUNDATION_EXPORT NSString * const RSXcodeClassSourceCodeSourceContent;
@end
