//
//  main.m
//  RSXcodeClassSourceCodeGen
//
//  Created by closure on 3/21/14.
//  Copyright (c) 2014 closure. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "RSXcodeClassSourceCodeGen.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        if (argc != 3) {
            NSLog(@"usage: RSXcodeClassSourceCodeGen content-path class-name");
            return -1;
        }
        NSLog(@"RSXcodeClassSourceCodeGen start");
        NSDictionary *content = [[NSDictionary alloc] initWithContentsOfFile:[[NSString stringWithUTF8String:argv[1]] stringByStandardizingPath]];
        if (!content) {
            return 1;
        }
        RSXcodeClassSourceCodeGen *xcode = [[RSXcodeClassSourceCodeGen alloc] initWithDictionary:content propertyNameGenHandler: [RSXcodeClassSourceCodeGen defaultPropertyNameGen]];
        id genContent = [xcode contentWithClassName:[NSString stringWithUTF8String:argv[2]]];
        
        [genContent[RSXcodeClassSourceCodeHeaderContent] writeToFile:[[NSString stringWithFormat:@"~/Desktop/%@.h", [NSString stringWithUTF8String:argv[2]]] stringByStandardizingPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [genContent[RSXcodeClassSourceCodeSourceContent] writeToFile:[[NSString stringWithFormat:@"~/Desktop/%@.m", [NSString stringWithUTF8String:argv[2]]] stringByStandardizingPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return 0;
}
