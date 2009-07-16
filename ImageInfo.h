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
#define IILatitude @"lat"
#define IILongitude @"lon"
#define IICapacity 6

@interface ImageInfo : NSObject {
    NSMutableDictionary *infoDict;
    NSString *originalLatitude;
    NSString *originalLongitude;
    BOOL validImage;
}
@property BOOL validImage;
@property (copy) NSString *originalLatitude;
@property (copy) NSString *originalLongitude;

@property (readonly) NSString *path;
@property (readonly) NSString *name;
@property (readonly) NSString *date;
@property (readonly) NSString *latitude;
@property (readonly) NSString *longitude;


+ (id) imageInfoWithPath: (NSString *) path;

- (void) setLocationToLatitude: (NSString *) lat
		     longitude: (NSString *) lng;
- (void) saveLocation;
- (void) revertLocation;
- (NSString *) stringRepresentation;
- (BOOL) convertFromString: (NSString *) representation
		  latitude: (NSString **) lat
		 longitude: (NSString **) lng;

@end
