//
//  RSXcodeClassSourceCodeGen.m
//  RSXcodeClassHolder
//
//  Created by closure on 3/21/14.
//  Copyright (c) 2014 closure. All rights reserved.
//

#import "RSXcodeClassSourceCodeGen.h"

@protocol RSXcodeProtocolDefinitionDelegate <NSObject>

@optional
- (NSString *)keywordOfStartingDefinition;
- (NSString *)keywordOfFinishingDefinition;

- (NSArray *)protocols;
@end

@protocol RSXcodeClassDefinitionDelegate <NSObject>
@required
- (NSString *)className;
- (BOOL)hasProtocol;

@optional
- (NSString *)keywordOfStartingDefinition;
- (NSString *)keywordOfFinishingDefinition;
- (NSString *)keywordOfStartingImplementation;
- (NSString *)keywordOfFinishingImplementation;

- (NSString *)rootClass;

- (id<RSXcodeProtocolDefinitionDelegate>)protocolGenDelegate;
@end

@protocol RSXcodeClassGenDataSource <NSObject>
@required
- (NSArray *)keys;
- (NSArray *)types;
- (NSArray *)propertyNames;
@end

@interface __RSXcodeProtocolDefaultDefinitionDelegate : NSObject <RSXcodeProtocolDefinitionDelegate> {
    
}
- (instancetype)init;
@end

@implementation __RSXcodeProtocolDefaultDefinitionDelegate
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (NSString *)keywordOfStartingDefinition {
    return @"<";
}

- (NSString *)keywordOfFinishingDefinition {
    return @">";
}

- (NSArray *)protocols {
    return @[@"NSCoding"];
}
@end


@interface __RSXcodeClassDefaultDefinitionDelegate : NSObject <RSXcodeClassDefinitionDelegate> {
@private
    NSString *_className;
    id <RSXcodeProtocolDefinitionDelegate> _protocolGen;
}
- (instancetype)initWithClassName:(NSString *)className protocolGenDelegate:(id <RSXcodeProtocolDefinitionDelegate>)protocolDelegate;
@end

@implementation __RSXcodeClassDefaultDefinitionDelegate

- (instancetype)initWithClassName:(NSString *)className protocolGenDelegate:(id <RSXcodeProtocolDefinitionDelegate>)protocolDelegate {
    if (self = [super init]) {
        _className = className;
        _protocolGen = protocolDelegate ? : [[__RSXcodeProtocolDefaultDefinitionDelegate alloc] init];
    }
    return self;
}

- (NSString *)className {
    return _className;
}

- (BOOL)hasProtocol {
    return _protocolGen ? YES : NO;
}

- (NSString *)keywordOfStartingDefinition {
    return @"@interface";
}

- (NSString *)keywordOfFinishingDefinition {
    return @"@end";
}

- (NSString *)keywordOfStartingImplementation {
    return @"@implementation";
}

- (NSString *)keywordOfFinishingImplementation {
    return @"@end";
}

- (NSString *)rootClass {
    return @"NSObject";
}

- (id <RSXcodeProtocolDefinitionDelegate>)protocolGenDelegate {
    return _protocolGen;
}

@end


@interface RSXcodeClassSourceCodeGen () <RSXcodeClassGenDataSource, NSCoding>
@property (strong, nonatomic) NSMutableArray *keys;
@property (strong, nonatomic) NSMutableArray *types;
@property (strong, nonatomic) NSMutableArray *propertyNames;
@property (strong, nonatomic) NSString *(^propertyNameGen)(NSString *);
@property (weak, nonatomic)   id<RSXcodeClassDefinitionDelegate> genClassDelegate;

- (BOOL)_anaylze:(NSString *(^)(NSString *))propertyNameGen;
- (NSString *)_genClassDefinationWithName:(NSString *)className delegate:(id<RSXcodeClassDefinitionDelegate>)aDelegate dataSource:(id <RSXcodeClassGenDataSource>)dataSource;
@end

NSString * const RSXcodeClassSourceCodeHeaderContent = @"RSXcodeClassSourceCodeHeaderContent";
NSString * const RSXcodeClassSourceCodeSourceContent = @"RSXcodeClassSourceCodeSourceContent";

@implementation RSXcodeClassSourceCodeGen

+ (NSString *(^)(NSString *))defaultPropertyNameGen {
    return ^NSString *(NSString *key) {
        NSArray *parts = [key componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_ -"]];
        NSLog(@"%@ -> %@", key, parts);
        if ([parts count] > 1) {
            NSMutableString *result = [[NSMutableString alloc] init];
            [result appendString:[parts firstObject]];
            [parts enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [parts count] - 1)] options:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [result appendString: [obj capitalizedString]];
            }];
            
            return result;
        }
        return key;
    };
}

- (instancetype)initWithDictionary:(NSDictionary *)info propertyNameGenHandler:(NSString *(^)(NSString *))propertyNameGen {
    if (self = [super init]) {
        _info = info;
        _keys = [[NSMutableArray alloc] init];
        _types = [[NSMutableArray alloc] init];
        _propertyNames = [[NSMutableArray alloc] init];
        _propertyNameGen = propertyNameGen;
    }
    return self;
}

- (id)_genClassDefinationWithName:(NSString *)className delegate:(id<RSXcodeClassDefinitionDelegate>)aDelegate dataSource:(id <RSXcodeClassGenDataSource>)dataSource {
    NSMutableDictionary *rst = [[NSMutableDictionary alloc] init];
    NSMutableString *content = [[NSMutableString alloc] init];
    NSString *classStartingDefinition = [aDelegate keywordOfStartingDefinition];
    [content appendString:@"#import <Foundation/Foundation.h>\n"];
    [content appendFormat:@"%@ %@ : %@", classStartingDefinition, className, [aDelegate rootClass]];
    BOOL genProtocol = NO;
    if ([aDelegate hasProtocol]) {
        id <RSXcodeProtocolDefinitionDelegate> protocolGen = [aDelegate protocolGenDelegate];
        NSArray *protocols = [protocolGen protocols];
        NSUInteger cnt = [protocols count];
        if (cnt) {
            genProtocol = YES;
            NSString *protocolStartingDefinition = [protocolGen keywordOfStartingDefinition];
            [content appendFormat:@" %@", protocolStartingDefinition];
            [protocols enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (idx < cnt - 1) {
                    [content appendString:obj];
                    [content appendString:@", "];
                } else {
                    *stop = YES;
                }
            }];
            [content appendFormat:@"%@", [protocols lastObject]];
            NSString *protocolFinishingDefinition = [protocolGen keywordOfFinishingDefinition];
            [content appendFormat:@"%@", protocolFinishingDefinition];
        }
    }
    // gen main content
    NSMutableString *propertiesContent = nil;
    if ([dataSource propertyNames]) {
        propertiesContent = [[NSMutableString alloc] init];
        NSArray *propertyNames = [dataSource propertyNames];
        NSArray *types = [dataSource types];
        // gen class properties
        if (genProtocol)
            [content appendString:@" {\n"];
        else
            [content appendString:@"{\n"];
        if ([propertyNames count]) {
            [content appendFormat:@"\tid _info;"];
            [propertyNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                //                [content appendFormat:@"\t%@ *_%@;", types[idx], obj];
                [propertiesContent appendFormat:@"@property (strong, nonatomic) %@ *%@;\n", types[idx], obj];
            }];
        }
        [content appendString:@"\n}\n"];
        [content appendString:propertiesContent];
    } else {
        [content appendString:@"\n"];
    }
    
    [content appendString:@"- (instancetype)initWithInfo:(NSDictionary *)info;\n"];
    /*
     - (id)initWithContentsOfFile:(NSString *)path;
     - (id)initWithData:(NSData *)data;
     - (instancetype)initWithInfo:(NSDictionary *)info;
     - (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_8, 6_0);
     - (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_8, 6_0);
     */
    [content appendString:@"- (id)initWithContentsOfFile:(NSString *)path;\n"];
    [content appendString:@"- (id)initWithData:(NSData *)data;\n"];
    NSString *classFinishingDefinition = [aDelegate keywordOfFinishingDefinition];
    [content appendFormat:@"%@\n", classFinishingDefinition];
    
    [content appendFormat:@"\n"];
    
    rst[RSXcodeClassSourceCodeHeaderContent] = content;
    
    content = nil;
    content = [[NSMutableString alloc] init];
    
    // gen implementation
    [content appendFormat:@"#import \"%@.h\"\n", className];
    
    NSString *classStartingImplementation = [aDelegate keywordOfStartingImplementation];
    [content appendFormat:@"%@ %@\n\n", classStartingImplementation, className];
    
    if ([dataSource propertyNames]) {
        propertiesContent = [[NSMutableString alloc] init];
        NSArray *propertyNames = [dataSource propertyNames];
        NSArray *types = [dataSource types];
        // gen class properties
        if ([propertyNames count]) {
            NSArray *keys = [dataSource keys];
            [propertyNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                //                [content appendFormat:@"\t%@ *_%@;", types[idx], obj];
                [propertiesContent appendFormat:@"- (%@ *)%@ {\n\treturn _info[@\"%@\"];\n}\n\n", types[idx], obj, keys[idx]];
            }];
        }
        [content appendString:propertiesContent];
    } else {
        [content appendString:@"\n"];
    }
    
    [content appendString:@"- (instancetype)initWithInfo:(NSDictionary *)info {\n\tif (self = [super init]) {\n\t\t_info = info;\n\t}\n\treturn self;\n}\n\n"];
    [content appendString:@"- (instancetype)initWithContentOfFile:(NSString *)path {\n\tif (self = [super init]) {\n\t\t_info = [[NSDictionary alloc] initWithContentOfFile:path];\n\t}\n\treturn self;\n}\n\n"];
    [content appendString:@"- (instancetype)initWithCoder:(NSCoder *)aDecoder {\n\tif (self = [super init]) {\n\t\t_info = [aDecoder decodeObject];\n\t}\n\treturn self;\n}\n\n"];
    [content appendString:@"- (void)encodeWithCoder:(NSCoder *)aCoder {\n\t[aCoder encodeObject:_info];\n}\n"];
    
    NSString *classFinishingImplementation = [aDelegate keywordOfFinishingImplementation];
    [content appendFormat:@"%@\n", classFinishingImplementation];
    
    rst[RSXcodeClassSourceCodeSourceContent] = content;
    return rst;
}

- (id)contentWithClassName:(NSString *)className {
    [self _anaylze:_propertyNameGen];
    return [self _genClassDefinationWithName:className delegate:_genClassDelegate ? : [[__RSXcodeClassDefaultDefinitionDelegate alloc] initWithClassName:className protocolGenDelegate:nil] dataSource:self];
}

#define GEN_CLASS_WITH(cls)  ([obj isKindOfClass:[cls class]]) {\
                                [_types addObject:@(#cls)];\
                            }

- (BOOL)_anaylze:(NSString *(^)(NSString *))propertyNameGen {
    [_info enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [_keys addObject:key];
        do {
            if GEN_CLASS_WITH(NSString)
            else if GEN_CLASS_WITH(NSDictionary)
            else if GEN_CLASS_WITH(NSArray)
            else if GEN_CLASS_WITH(NSData)
            else if GEN_CLASS_WITH(NSDate)
            else if GEN_CLASS_WITH(NSNumber)
            else if GEN_CLASS_WITH(NSMutableString)
            else if GEN_CLASS_WITH(NSMutableDictionary)
            else if GEN_CLASS_WITH(NSMutableArray)
            else if GEN_CLASS_WITH(NSMutableData)
            else {
                [_types addObject:[obj className]];
            }
        } while (0);
        
        [_propertyNames addObject:propertyNameGen(key)];
    }];
    return NO;
}

@end
