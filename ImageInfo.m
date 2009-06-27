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
	infoDict = [NSMutableDictionary dictionaryWithObject: path
						      forKey: IIPathName];
	[infoDict setObject: [path lastPathComponent] forKey: IIImageName];
	validImage = [self callExiftoolForFileAt: path];
    }
    return self;
}

- (NSString *) path
{
    return [infoDict objectForKey: IIPathName];
}

- (NSString *) name
{
    return [infoDict objectForKey: IIImageName];
}

- (NSString *) date
{
    return [infoDict objectForKey: IIDateTime];
}

- (NSString *) latitude
{
    return [infoDict objectForKey: IILatitude];
}

- (NSString *) longitude
{
    return [infoDict objectForKey: IILongitude];
}

#pragma mark -
#pragma mark helper functions

- (BOOL) callExiftoolForFileAt: (NSString *) path
{
    NSTask *exiftool = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    
    [exiftool setStandardOutput: newPipe];
    [exiftool setStandardError: [NSFileHandle fileHandleWithNullDevice]];
    [exiftool setLaunchPath:[GTDefaultsController exiftoolPath]];
    [exiftool setArguments:[NSArray arrayWithObjects: @"-S", @"-filetype",
			    @"-filemodifydate",@"-datetimeoriginal",
			    @"-GPSLatitude", @"-GPSLongitude",
			    path, nil]];
    [exiftool launch];
    
    inData = [readHandle readDataToEndOfFile];
    [readHandle closeFile];
    if ([inData length]) {
	NSString *s = [[NSString alloc] initWithData: inData
					    encoding: NSASCIIStringEncoding];
	NSArray *a = [s componentsSeparatedByString:@"\n"];
	NSLog(@"exif data: %@", a);
	;;;
    }
    [exiftool waitUntilExit];
    NSLog(@"exiftool returned %d", [exiftool terminationStatus]);
    return [exiftool terminationStatus] == 0;
}


@end
