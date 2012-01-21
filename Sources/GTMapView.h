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
    BOOL hiddenMarker;
}

@property (strong) id appController;
@property (copy) NSString *mapLat;
@property (copy) NSString *mapLng;
@property (assign, getter=isHiddenMarker) BOOL hiddenMarker;

+ (BOOL) isSelectorExcludedFromWebScript: (SEL) selector;
+ (BOOL) isKeyExcludedFromWebScript: (const char *) property;
+ (NSString *) webScriptNameForSelector: (SEL) sel;

- (void) loadMap;
- (void) hideMarker: (NSString *) name;
- (void) adjustMapForLatitude: (CGFloat) lat
		    longitude: (CGFloat) lng
			 name: (NSString *) name;

- (void) reportPosition;

@end
