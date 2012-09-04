//
//  ImageInfo.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import "ImageInfo.h"
#import "GTDefaultsController.h"

/*
 * info dictionary keys
 */
#define IIPathName @"path"
#define IIImageName @"fn"
#define IIDateTime @"dt"
#define IICapacity 4

@implementation ImageInfo {
    NSMutableDictionary *_infoDict;
}

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
        _infoDict = [NSMutableDictionary dictionaryWithObject: path
                                                       forKey: IIPathName];
        _infoDict[IIImageName] = [path lastPathComponent];
        _image = nil;
        _latitude = 0.0;
        _longitude = 0.0;
        _originalLatitude = 0.0;
        _originalLongitude = 0.0;
        _validLocation = NO;
        _validOriginalLocation = NO;
        _validImage = [self getInfoForFileAt: path];
        if (_validImage) {
            _validOriginalLocation = _validLocation;
            _originalLatitude = _latitude;
            _originalLongitude = _longitude;
        }
    }
    return self;
}

- (NSString *) path
{
    return _infoDict[IIPathName];
}

- (NSString *) name
{
    return _infoDict[IIImageName];
}

- (NSString *) date
{
    return _infoDict[IIDateTime];
}

- (NSString *) latitudeAsString
{
    if (self.validLocation)
	return [NSString stringWithFormat: @"%f", [self latitude]];
    return @"";

}

- (NSString *) longitudeAsString
{
    if (self.validLocation)
	return [NSString stringWithFormat: @"%f", [self longitude]];
    return @"";
}

#pragma mark -
#pragma mark string representation methods

- (NSString *) stringRepresentation
{
    if (self.validLocation)
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
	self.latitude = [lat doubleValue];
	self.longitude = [lng doubleValue];
	self.validLocation = YES;
    } else
	self.validLocation = NO;
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
    if ((self.validLocation != self.validOriginalLocation) ||
	(self.latitude != self.originalLatitude) ||
	(self.longitude != self.originalLongitude)) {

	if ([GTDefaultsController makeBackupFiles])
	    [self backupFile];

	NSMutableString *latArg =
	    [NSMutableString stringWithString: @"-GPSLatitude="];
	NSMutableString *latRefArg =
	    [NSMutableString stringWithString: @"-GPSLatitudeRef="];
	if (self.validLocation) {
	    CGFloat lat = self.latitude;
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
	if (self.validLocation) {
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
        self.originalLatitude = self.latitude;
        self.originalLongitude = self.longitude;
    }
}

- (void) revertLocation
{
    self.validLocation = self.validOriginalLocation;
    self.latitude = self.originalLatitude;
    self.longitude = self.originalLongitude;
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

    // get metadata
    NSDictionary *metadata =
        (__bridge_transfer NSDictionary *) CGImageSourceCopyPropertiesAtIndex(iRef, 0, NULL);

    // get a reasonable sized thumbnail
    NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
        (id) kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
        [NSNumber numberWithInt:1024], kCGImageSourceThumbnailMaxPixelSize,
        nil];
    CGImageRef preview = CGImageSourceCreateThumbnailAtIndex(iRef, 0, (__bridge CFDictionaryRef) opts);
    NSRect imageRect= NSMakeRect(0.0, 0.0, 0.0, 0.0);
    imageRect.size.height = CGImageGetHeight(preview);
    imageRect.size.width = CGImageGetWidth(preview);
    self.image = [[NSImage alloc] initWithSize:imageRect.size];
    [self.image lockFocus];
    CGContextDrawImage([[NSGraphicsContext currentContext] graphicsPort],
                       *(CGRect*)&imageRect, preview);
    [self.image unlockFocus];
    CGImageRelease(preview);
    CFRelease(iRef);

    // image creation date/time
    NSDictionary *exifdata = (NSDictionary *)
	metadata[(NSString *) kCGImagePropertyExifDictionary];
    if (exifdata) {
	NSString *date = exifdata[(NSString *) kCGImagePropertyExifDateTimeOriginal];
	if (date)
	    _infoDict[IIDateTime] = [NSString stringWithString: date];
    }

    // latitude and longitude
    NSDictionary *gpsdata = (NSDictionary *)
	metadata[(NSString *) kCGImagePropertyGPSDictionary];
    if (gpsdata) {
	NSString *lat = gpsdata[(NSString *) kCGImagePropertyGPSLatitude];
	if (lat) {
	    NSString *latRef = gpsdata[(NSString *) kCGImagePropertyGPSLatitudeRef];
	    if (latRef && [latRef isEqualToString: @"N"])
		self.latitude = [lat doubleValue];
	    else
                self.latitude = -[lat doubleValue];
	    self.validLocation = YES;
	}
    
	NSString *lng = gpsdata[(NSString *) kCGImagePropertyGPSLongitude];
	if (lng) {
	    NSString *lngRef = gpsdata[(NSString *) kCGImagePropertyGPSLongitudeRef];
	    if (lngRef && [lngRef isEqualToString: @"E"])
                self.longitude = [lng doubleValue];
	    else
                self.longitude = -[lng doubleValue];
            self.validLocation = YES;
	}
    }
    return YES;
}

@end
