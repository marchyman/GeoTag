//
//  ImageInfo.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import <Cocoa/Cocoa.h>

/*
 * info dictionary keys
 */
#define IIPathName @"path"
#define IIImageName @"fn"
#define IIDateTime @"dt"
#define IICapacity 4

@interface ImageInfo : NSObject {
    NSImage *image;
    NSMutableDictionary *infoDict;
    CGFloat latitude;
    CGFloat longitude;
    CGFloat originalLatitude;
    CGFloat originalLongitude;
    BOOL validLocation;
    BOOL validOriginalLocation;
    BOOL validImage;
}
@property (strong) NSImage *image;
@property CGFloat latitude;
@property CGFloat longitude;
@property CGFloat originalLatitude;
@property CGFloat originalLongitude;
@property BOOL validLocation;
@property BOOL validOriginalLocation;
@property BOOL validImage;

@property (unsafe_unretained, readonly) NSString *path;
@property (unsafe_unretained, readonly) NSString *name;
@property (unsafe_unretained, readonly) NSString *date;
@property (unsafe_unretained, readonly) NSString *latitudeAsString;
@property (unsafe_unretained, readonly) NSString *longitudeAsString;

+ (id) imageInfoWithPath: (NSString *) path;

- (void) setLocationToLatitude: (NSString *) lat
		     longitude: (NSString *) lng;
- (void) saveLocationWithGroup: (dispatch_group_t) dispatchGroup;
- (void) revertLocation;
- (NSString *) stringRepresentation;
- (BOOL) convertFromString: (NSString *) representation
		  latitude: (NSString **) lat
		 longitude: (NSString **) lng;

@end
