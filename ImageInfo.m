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

#pragma mark -
#pragma mark Class methods

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

#pragma mark -
#pragma mark init and property accessors

- (id) init
{
    self = [super init];
    if (self) {
	info = [NSMutableDictionary dictionaryWithCapacity: IICapacity];
	validImage = NO;
    }
    return self;
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
    return NO;
}

@end
