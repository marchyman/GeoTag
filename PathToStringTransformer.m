//
//  PathToStringTransformer.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/18/09.
//

#import "PathToStringTransformer.h"


@implementation PathToStringTransformer

+ (Class) transformedValueClass
{
    return [NSURL class];
}

+ (BOOL) allowReverseTransformation
{
    return YES;
}

- (id) transformedValue: (id) value
{
    id result = nil;
    
    if (value)
	result = [NSURL URLWithString: value
			relativeToURL: [NSURL URLWithString:
					@"file://localhost/"]];
    return result;
}

- (id) reverseTransformedValue: (id) value
{
    id result = nil;
    
    if (value)
	result = [value path];
    return result;
}

@end
