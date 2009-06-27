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

- (NSString *) imagePath
{
    return [info objectForKey: IIPathName];
}

- (NSString *) imageName
{
    return [info objectForKey: IIImageName];
}

- (NSString *) imageDate
{
    return [info objectForKey: IIDateTime];
}

- (NSString *) imageLat
{
    return [info objectForKey: IILatitude];
}

- (NSString *) imageLon
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
