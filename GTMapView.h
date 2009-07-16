//
//  GTMapView.h
//  GeoTag
//
//  Created by Marco S Hyman on 7/16/09.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface GTMapView : NSObject {
    IBOutlet WebView *webView;

    id appController;
    NSString *mapLat;
    NSString *mapLng;
}

- (id) initWithController: (id) controller;

- (void) adjustMapForLatitude: (NSString *) lat
		    longitude: (NSString *) lng
			 name: (NSString *) name;

- (void) reportPosition;

@end
