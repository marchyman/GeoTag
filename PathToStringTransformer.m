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
    if (value)
	return [NSURL URLWithString: value
		      relativeToURL: [NSURL URLWithString:@"file://localhost/"]];
    return nil;
}

- (id) reverseTransformedValue: (id) value
{
    if (value)
	return [value path];
    return nil;
}

@end
