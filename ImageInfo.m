//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"

@interface ImageInfo ()
- (NSMutableDictionary *) info;
- (void) setInfo: (NSMutableDictionary *) newInfo;
@end

@implementation ImageInfo
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

- (NSMutableDictionary *) info
{
    return info;
}

- (void) setInfo: (NSMutableDictionary *) newInfo
{
    [info autorelease];
    info = [newInfo retain];
}

- (BOOL) parseExif
{
    ;;;
    return NO;
}

@end
