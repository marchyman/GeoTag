//
//  ImageInfo.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/15/09.
//

#import <Cocoa/Cocoa.h>

@interface ImageInfo : NSObject

@property (strong) NSImage *image;
@property CGFloat latitude;
@property CGFloat longitude;
@property CGFloat originalLatitude;
@property CGFloat originalLongitude;
@property BOOL validLocation;
@property BOOL validOriginalLocation;
@property BOOL validImage;

@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *date;
@property (readonly, nonatomic) NSString *latitudeAsString;
@property (readonly, nonatomic) NSString *longitudeAsString;

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
