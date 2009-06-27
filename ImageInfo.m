//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"
#import "GTDefaultsController.h"

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

- (BOOL) callExiftool: (NSString *) path
{
    NSTask *exiftool = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    
    [exiftool setStandardOutput: newPipe];
    [exiftool setStandardError: [NSFileHandle fileHandleWithNullDevice]];
    [exiftool setLaunchPath:[GTDefaultsController exiftoolPath]];
    [exiftool setArguments:[NSArray arrayWithObjects: @"-S",
	@"-datetimeoriginal", @"-GPSLatitude", @"-GPSLongitude",
			    path, nil]];
    [exiftool launch];
    
    while ((inData = [readHandle readDataToEndOfFile]) && [inData length]) {
        NSLog(@"read data: %@", inData);
    }
    [exiftool waitUntilExit];
    NSLog(@"exiftool returned %d", [exiftool terminationStatus]);
    return [exiftool terminationStatus] == 0;
}

- (BOOL) parseExif
{
    NSString *path = [info objectForKey: IIPathName];
    [info setObject: [path lastPathComponent] forKey: IIImageName];
    BOOL validExif = [self callExiftool: path];
    if (validExif) {
	;;;
    }
    return validExif;
}

@end
