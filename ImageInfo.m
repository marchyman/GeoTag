//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"

@implementation ImageInfo
@synthesize info;
@synthesize validImage;

+ (id) imageInfoWithPath: (NSString *) path
{
    ImageInfo *newInfo = [[ImageInfo alloc] init];
    if (newInfo) {
	[newInfo setInfo: [NSMutableDictionary dictionaryWithObject: path
							     forKey: IIPathName]];
	[newInfo setValidImage: [newInfo parseExif]];
    }
    return newInfo;
}

- (id) init
{
    self = [super init];
    if (self) {
	info = [[NSMutableDictionary dictionaryWithCapacity: IICapacity] retain];
	validImage = NO;
    }
    return self;
}

- (void) dealloc
{
    [info release];
    [super dealloc];
}

#pragma mark properties

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

#pragma mark helper functions

- (BOOL) parseExif
{
    NSString *path = [info objectForKey: IIPathName];
    [info setObject: [path lastPathComponent] forKey: IIImageName];
    ;;;
    return NO;
}

@end
