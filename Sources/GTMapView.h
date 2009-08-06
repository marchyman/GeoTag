//
//  GTMapView.h
//  GeoTag
//
//  Created by Marco S Hyman on 7/16/09.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface GTMapView : WebView {
    id appController;
    NSString *mapLat;
    NSString *mapLng;
}

@property (retain) id appController;
@property (copy) NSString *mapLat;
@property (copy) NSString *mapLng;

+ (BOOL) isSelectorExcludedFromWebScript: (SEL) selector;
+ (BOOL) isKeyExcludedFromWebScript: (const char *) property;
+ (NSString *) webScriptNameForSelector: (SEL) sel;

- (void) loadMap;
- (void) hideMarker;
- (void) adjustMapForLatitude: (CGFloat) lat
		    longitude: (CGFloat) lng
			 name: (NSString *) name;

- (void) reportPosition;

@end
