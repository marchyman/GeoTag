//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"

@implementation ImageInfo
@synthesize validImage;

#pragma mark -
#pragma mark Convenience methods

+ (id) imageInfoWithPath: (NSString *) path
{
    return [[ImageInfo alloc] initWithPath: path];
}

#pragma mark -
#pragma mark init and property accessors

- (id) initWithPath: (NSString *) path
{
    self = [super init];
    if (self) {
	info = [NSMutableDictionary dictionaryWithObject: path
						  forKey: IIPathName];
	validImage = [self parseExif];
    }
    return self;
}

- (NSString *) path
{
    return [info objectForKey: IIPathName];
}

- (NSString *) name
{
    return [info objectForKey: IIImageName];
}

- (NSString *) date
{
    return [info objectForKey: IIDateTime];
}

- (NSString *) latitude
{
    return [info objectForKey: IILatitude];
}

- (NSString *) longitude
{
    return [info objectForKey: IILongitude];
}

#pragma mark -
#pragma mark helper functions

- (BOOL) parseExif
{
    NSString *path = [info objectForKey: IIPathName];
    [info setObject: [path lastPathComponent] forKey: IIImageName];
    ;;;
    // temp code for testing
    static int counter;
    return ++counter % 2 ? YES : NO;
}

@end
