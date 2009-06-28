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
	validImage = [self getExifInfoForFileAt: path];
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

- (BOOL) checkTypeWithValue: (NSString *) val
{
    return ([val caseInsensitiveCompare: @"jpeg"] == NSOrderedSame) ||
    ([val caseInsensitiveCompare: @"cr2"] == NSOrderedSame);
}

- (BOOL) checkTag: (NSString *) tag
	withValue: (NSString *) val
{
    BOOL ok = YES;

    NSLog(@"tag %@: %@", tag, val);
    if ([tag caseInsensitiveCompare: @"filetype"] == NSOrderedSame)
	ok = [self checkTypeWithValue: val];
    else if ([tag caseInsensitiveCompare: @"filemodifydate"] == NSOrderedSame)
	[infoDict setObject: val forKey: IIDateTime];
    else if ([tag caseInsensitiveCompare:@"datetimeoriginal"] == NSOrderedSame)
	// yes, this is supposed to overwrite filemodifydate
	[infoDict setObject: val forKey: IIDateTime];
    else if ([tag caseInsensitiveCompare:@"gpslatitude"] == NSOrderedSame)
	[infoDict setObject: val forKey: IILatitude];
    else if ([tag caseInsensitiveCompare:@"gpslongitude"] == NSOrderedSame)
	[infoDict setObject: val forKey: IILongitude];
    else
	ok = NO;
    return ok;
}

- (BOOL) getExifInfoForFileAt: (NSString *) path
{
    BOOL validExif = NO;
    NSTask *exiftool = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    
    [exiftool setStandardOutput: newPipe];
    [exiftool setStandardError: [NSFileHandle fileHandleWithNullDevice]];
    [exiftool setLaunchPath:[GTDefaultsController exiftoolPath]];
    [exiftool setArguments:[NSArray arrayWithObjects: @"-S", @"-c %.6f˚",
			    @"-filetype", @"-filemodifydate",
			    @"-datetimeoriginal",
			    @"-GPSLatitude", @"-GPSLongitude",
			    path, nil]];
    [exiftool launch];
    
    inData = [readHandle readDataToEndOfFile];
    [readHandle closeFile];
    if ([inData length]) {
	NSString *s = [[NSString alloc] initWithData: inData
					    encoding: NSASCIIStringEncoding];
	NSArray *a = [s componentsSeparatedByString:@"\n"];
	// at this point assume a valid image file until proven otherwise
	validExif = YES;
	for (NSString *anEntry in a) {
	    if ([anEntry length] > 0) {
		NSArray *tagAndValue =
		    [anEntry componentsSeparatedByString:@": "];
		if ([tagAndValue count] == 2)
		    if (! [self checkTag: [tagAndValue objectAtIndex:0]
			       withValue: [tagAndValue objectAtIndex:1]]) {
			validExif = NO;
			break;
		    }
	    }
	}
    }
    [exiftool waitUntilExit];
    return validExif;
}


@end
