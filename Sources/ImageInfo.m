//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"
#import "GTDefaultsController.h"

@interface ImageInfo ()
- (BOOL) getInfoForFileAt: (NSString *) path;
@end

@implementation ImageInfo

#pragma mark -
#pragma mark Class methods

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
	infoDict[IIImageName] = [path lastPathComponent];
	validImage = [self getInfoForFileAt: path];
	if (validImage) {
	    [self setValidOriginalLocation: [self validLocation]];
	    [self setOriginalLatitude: [self latitude]];
	    [self setOriginalLongitude: [self longitude]];
	    [self setImage: [[NSImage alloc] initWithContentsOfFile: path]];
	    /* ;;; make the above a concurrent operation */
	}
    }
    return self;
}

- (NSString *) path
{
    return infoDict[IIPathName];
}

- (NSString *) name
{
    return infoDict[IIImageName];
}

- (NSString *) date
{
    return infoDict[IIDateTime];
}

- (NSString *) latitudeAsString
{
    if ([self validLocation])
	return [NSString stringWithFormat: @"%f", [self latitude]];
    return @"";

}

- (NSString *) longitudeAsString
{
    if ([self validLocation])
	return [NSString stringWithFormat: @"%f", [self longitude]];
    return @"";
}

#pragma mark -
#pragma mark string representation methods

- (NSString *) stringRepresentation
{
    if ([self validLocation])
	return [NSString stringWithFormat: @"%f %f", [self latitude],
		[self longitude]];
    return @"";
}

- (BOOL) convertFromString: (NSString *) representation
		  latitude: (NSString **) lat
		 longitude: (NSString **) lng
{
    double latAsDouble, lngAsDouble;
    NSScanner *scanner = [NSScanner scannerWithString: representation];
    if (! [scanner scanDouble: &latAsDouble] ||
	latAsDouble < -90.0 ||
	latAsDouble > 90.0)
	return NO;
    if (! [scanner scanDouble: &lngAsDouble] ||
	lngAsDouble < -180.0 ||
	lngAsDouble > 180.0)
	return NO;
    if (! [scanner isAtEnd])
	return NO;
    *lat = [NSString stringWithFormat: @"%f", latAsDouble];
    *lng = [NSString stringWithFormat: @"%f", lngAsDouble];
    return YES;
}

#pragma mark -
#pragma mark update postion

/*
 * A null lat/lng will mark the image as not having a valid location
 */
- (void) setLocationToLatitude: (NSString *) lat longitude: (NSString *) lng
{
    if (lat && lng) {
	[self setLatitude: [lat doubleValue]];
	[self setLongitude: [lng doubleValue]];
	[self setValidLocation: YES];
    } else
	[self setValidLocation: NO];
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
	[fileManager copyItemAtPath: [self path]
			     toPath: dest
			      error: NULL];
}

/*
 * I was going to re-write to not use exiftool but...
 * when using core graphics functions to do this I discovered that
 * the image changed as well as the metadata.  Also, some metadata
 * was lost unless explicitly saved even though it didn't change.
 * (Conjecture: I didn't actually try to save it).
 *
 * I'll stick with exiftool for now.
 */
- (void) saveLocationWithGroup: (dispatch_group_t) dispatchGroup
{
    if (([self validLocation] != [self validOriginalLocation]) ||
	([self latitude] != [self originalLatitude]) ||
	([self longitude] != [self originalLongitude])) {

	if ([GTDefaultsController makeBackupFiles])
	    [self backupFile];

	NSMutableString *latArg =
	    [NSMutableString stringWithString: @"-GPSLatitude="];
	NSMutableString *latRefArg =
	    [NSMutableString stringWithString: @"-GPSLatitudeRef="];
	if ([self validLocation]) {
	    CGFloat lat = [self latitude];
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
	if ([self validLocation]) {
	    CGFloat lng = [self longitude];
	    if (lng < 0) {
		[lngRefArg appendString: @"W"];
		lng = -lng;
	    } else
		[lngRefArg appendString: @"E"];
	    [lngArg appendFormat: @"%f", lng];
	}

        dispatch_queue_t dispatchQueue =
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_async(dispatchGroup, dispatchQueue, ^{
            NSTask *exiftool = [[NSTask alloc] init];
            [exiftool setStandardOutput: [NSFileHandle fileHandleWithNullDevice]];
            [exiftool setStandardError: [NSFileHandle fileHandleWithNullDevice]];
            [exiftool setLaunchPath:[GTDefaultsController exiftoolPath]];
            [exiftool setArguments:@[@"-q", @"-m",
                                    @"-overwrite_original",
                                    @"-gpsmapdatum=WGS-84",
                                    latArg, latRefArg, lngArg,
                                    lngRefArg, [self path]]];
            [exiftool launch];
            [exiftool waitUntilExit];
            ;;; // check for error?
        });
        [self setOriginalLatitude: [self latitude]];
        [self setOriginalLongitude: [self longitude]];
    }
}

- (void) revertLocation
{
    [self setValidLocation: [self validOriginalLocation]];
    [self setLatitude: [self originalLatitude]];
    [self setLongitude: [self originalLongitude]];
}

#pragma mark -
#pragma mark helper functions

- (BOOL) getInfoForFileAt: (NSString *) path
{
    NSURL *url = [NSURL fileURLWithPath: path];
    CGImageSourceRef iRef =
        CGImageSourceCreateWithURL((__bridge CFURLRef) url, NULL);
    if (! iRef)
	return NO;
    NSDictionary *metadata = 
        (__bridge_transfer NSDictionary *) CGImageSourceCopyPropertiesAtIndex(iRef, 0, NULL);
    CFRelease(iRef);

    // image creation date/time
    NSDictionary *exifdata = (NSDictionary *)
	metadata[(NSString *) kCGImagePropertyExifDictionary];
    if (exifdata) {
	NSString *date = exifdata[(NSString *) kCGImagePropertyExifDateTimeOriginal];
	if (date)
	    infoDict[IIDateTime] = [NSString stringWithString: date];
    }

    // latitude and longitude
    NSDictionary *gpsdata = (NSDictionary *)
	metadata[(NSString *) kCGImagePropertyGPSDictionary];
    if (gpsdata) {
	NSString *lat = gpsdata[(NSString *) kCGImagePropertyGPSLatitude];
	if (lat) {
	    NSString *latRef = gpsdata[(NSString *) kCGImagePropertyGPSLatitudeRef];
	    if (latRef && [latRef isEqualToString: @"N"])
		[self setLatitude: [lat doubleValue]];
	    else
		[self setLatitude: -[lat doubleValue]];
	    [self setValidLocation: YES];
	}
    
	NSString *lng = gpsdata[(NSString *) kCGImagePropertyGPSLongitude];
	if (lng) {
	    NSString *lngRef = gpsdata[(NSString *) kCGImagePropertyGPSLongitudeRef];
	    if (lngRef && [lngRef isEqualToString: @"E"])
		[self setLongitude: [lng doubleValue]];
	    else
		[self setLongitude: -[lng doubleValue]];
	    [self setValidLocation: YES];
	}
    }
    return YES;
}

@end
