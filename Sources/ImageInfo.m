//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"
#import "GTDefaultsController.h"

#if GTDEBUG == 0
#define NSLog(...)
#endif

static NSArray *knownFileTypes;

@interface ImageInfo ()
- (BOOL) getExifInfoForFileAt: (NSString *) path;
@end

@implementation ImageInfo
@synthesize originalLatitude;
@synthesize originalLongitude;
@synthesize validImage;
@synthesize orientation;

#pragma mark -
#pragma mark Class methods

+ (void) initialize
{
    if (! knownFileTypes)
	knownFileTypes = [NSArray arrayWithObjects: @"JPEG", @"CR2", @"CRW",
			    @"CS1", @"DCP", @"DNG", @"EPS", @"ERF", @"EXIF",
			    @"GIF", @"HDP", @"ICC", @"JNG", @"JP2", @"MEF",
			    @"MIE", @"MNG", @"MOS", @"MRW", @"NEF", @"NRW",
			    @"ORF", @"PBM", @"PDF", @"PEF", @"PGM", @"PNG",
			    @"PPM", @"PS", @"PSD", @"RAF", @"RAW", @"THM",
			    @"TIFF", @"WDP", @"XMP", nil];
}

+ (id) imageInfoWithPath: (NSString *) path
{
    return [[self alloc] initWithPath: path];
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
	originalLatitude = [self latitude];
	originalLongitude = [self longitude];
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
#pragma mark string representation methods

- (NSString *) stringRepresentation
{
    NSString *lat;
    NSString *lng;
    
    if ((lat = [self latitude]) && (lng = [self longitude]))
	return [NSString stringWithFormat: @"%@ %@", lat, lng];
    return @"";
}

- (BOOL) convertFromString: (NSString *) representation
		  latitude: (NSString **) lat
		 longitude: (NSString **) lng
{
    float latAsFloat, lngAsFloat;
    NSScanner *scanner = [NSScanner scannerWithString: representation];
    if (! [scanner scanFloat: &latAsFloat] ||
	latAsFloat < -90.0 ||
	latAsFloat > 90.0) {
	NSLog(@"Bad lat: %f", latAsFloat);
	return NO;
    }
    if (! [scanner scanFloat: &lngAsFloat] ||
	lngAsFloat < -180.0 ||
	lngAsFloat > 180.0) {
	NSLog(@"Bad lng: %f", lngAsFloat);
	return NO;
    }
    if (! [scanner isAtEnd]) {
	NSLog(@"scanner not at end of string: %@", representation);
	return NO;
    }
    *lat = [NSString stringWithFormat: @"%f", latAsFloat];
    *lng = [NSString stringWithFormat: @"%f", lngAsFloat];
    NSLog(@"in: %@ out: %@, %@", representation, *lat, *lng);
    return YES;
}

#pragma mark -
#pragma mark update postion

- (void) setLocationToLatitude: (NSString *) lat longitude: (NSString *) lng
{
    if (lat && lng) {
	[infoDict setObject: lat forKey: IILatitude];
	[infoDict setObject: lng forKey: IILongitude];
    } else
	[infoDict removeObjectsForKeys: [NSArray arrayWithObjects:
					 IILatitude, IILongitude, nil]];
}

#pragma mark -
#pragma mark update files

- (void) backupFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dest = [[NSHomeDirectory()
		       stringByAppendingPathComponent: @".Trash"]
		      stringByAppendingPathComponent: [self name]];
    if (! [fileManager fileExistsAtPath: dest])
	[fileManager copyPath: [self path]
		       toPath: dest
		      handler: nil];
}
- (void) saveLocation
{
    if ((! [[self latitude] isEqualToString: [self originalLatitude]]) ||
	(! [[self longitude] isEqualToString: [self originalLongitude]])) {

	if ([GTDefaultsController makeBackupFiles])
	    [self backupFile];

	NSMutableString *latArg =
	    [NSMutableString stringWithString: @"-GPSLatitude="];
	NSMutableString *latRefArg =
	    [NSMutableString stringWithString: @"-GPSLatitudeRef="];
	if ([self latitude]) {
	    float lat = [[self latitude] floatValue];
	    if (lat < 0) {
		[latRefArg appendString: @"S"];
		lat = -lat;
	    } else
		[latRefArg appendString: @"N"];
	    [latArg appendFormat: @"%f", lat];
	}

	NSMutableString *lngArg =
	    [NSMutableString stringWithString: @"-GPSLongitude="];
	NSMutableString *lngRefArg =
	    [NSMutableString stringWithString: @"-GPSLongitudeRef="];
	if ([self longitude]) {
	    float lng = [[self longitude] floatValue];
	    if (lng < 0) {
		[lngRefArg appendString: @"W"];
		lng = -lng;
	    } else
		[lngRefArg appendString: @"E"];
	    [lngArg appendFormat: @"%f", lng];
	}

	NSTask *exiftool = [[NSTask alloc] init];
	[exiftool setStandardOutput: [NSFileHandle fileHandleWithNullDevice]];
	[exiftool setStandardError: [NSFileHandle fileHandleWithNullDevice]];
	[exiftool setLaunchPath:[GTDefaultsController exiftoolPath]];
	[exiftool setArguments:[NSArray arrayWithObjects: @"-q", @"-m",
				@"-overwrite_original", @"-gpsmapdatum=WGS-84",
				latArg, latRefArg, lngArg, lngRefArg,
				[self path], nil]];
	[exiftool launch];
	[exiftool waitUntilExit];
	;;; // check for error?
	[self setOriginalLatitude: [self latitude]];
	[self setOriginalLongitude: [self longitude]];
    }
}

- (void) revertLocation
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    if ([self originalLatitude] && [self originalLongitude]) {
	[infoDict setObject: [self originalLatitude] forKey: IILatitude];
	[infoDict setObject: [self originalLongitude] forKey: IILongitude];
    } else if ([self latitude] || [self longitude])
	[infoDict removeObjectsForKeys: [NSArray arrayWithObjects:
					 IILatitude, IILongitude, nil]];
}

#pragma mark -
#pragma mark helper functions

- (BOOL) checkTag: (NSString *) tag
	withValue: (NSString *) val
{
    BOOL ok = YES;

    NSLog(@"tag %@: %@", tag, val);
    if ([tag caseInsensitiveCompare: @"filetype"] == NSOrderedSame)
	ok = [knownFileTypes containsObject: val];
    else if ([tag caseInsensitiveCompare: @"filemodifydate"] == NSOrderedSame)
	[infoDict setObject: val forKey: IIDateTime];
    else if ([tag caseInsensitiveCompare: @"datetimeoriginal"] == NSOrderedSame)
	// yes, this is supposed to overwrite filemodifydate
	[infoDict setObject: val forKey: IIDateTime];
    else if ([tag caseInsensitiveCompare: @"gpslatitude"] == NSOrderedSame) {
	NSArray *a = [val componentsSeparatedByString:@" "];
	if (([a count] == 2) &&
	    ([[a objectAtIndex: 1] compare: @"S"] == NSOrderedSame))
	    val = [@"-" stringByAppendingString: [a objectAtIndex: 0]];
	else
	    val = [a objectAtIndex: 0];
	[infoDict setObject: val forKey: IILatitude];
    } else if ([tag caseInsensitiveCompare:@"gpslongitude"] == NSOrderedSame) {
	NSArray *a = [val componentsSeparatedByString:@" "];
	if (([a count] == 2) &&
	    ([[a objectAtIndex: 1] compare: @"W"] == NSOrderedSame))
	    val = [@"-" stringByAppendingString: [a objectAtIndex: 0]];
	else
	    val = [a objectAtIndex: 0];
	[infoDict setObject: val forKey: IILongitude];
    } else if ([tag caseInsensitiveCompare:@"orientation"] == NSOrderedSame) {
	NSArray *a = [val componentsSeparatedByString:@" "];
	if ([a count] == 3)
	    [self setOrientation: [[a objectAtIndex: 1] floatValue]];
	NSLog(@"Orientation %f", [self orientation]);
    } else
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
    [exiftool setArguments:[NSArray arrayWithObjects: @"-S",
			    @"-coordFormat", @"%.6f",
			    @"-filetype", @"-filemodifydate",
			    @"-datetimeoriginal",
			    @"-GPSLatitude", @"-GPSLongitude",
			    @"-Orientation", path, nil]];
    [exiftool launch];
    
    inData = [readHandle readDataToEndOfFile];
    [readHandle closeFile];
    if ([inData length]) {
	NSString *s = [[NSString alloc] initWithData: inData
					    encoding: NSASCIIStringEncoding];
	// The first tag must match "FileType"
	validExif = [s hasPrefix: @"FileType"];
	NSArray *a = [s componentsSeparatedByString:@"\n"];
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
