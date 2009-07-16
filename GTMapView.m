//
//  GTWebView.m
//  GeoTag
//
//  Created by Marco S Hyman on 7/16/09.
//

#import "GTMapView.h"


@implementation GTMapView

#pragma mark -
#pragma mark WebScripting Protocol methods

// only the report selector can be called from the script
+ (BOOL) isSelectorExcludedFromWebScript: (SEL) selector
{
    if (selector == @selector(report))
	return NO;
    return YES;
}

// the script has access to mapLat and mapLng variables
+ (BOOL) isKeyExcludedFromWebScript: (const char *) property
{
    if ((strcmp(property, "webLat") == 0) ||
	(strcmp(property, "webLng") == 0))
        return NO;
    return YES;
    
}

// no script-to-selector name translation needed
+ (NSString *) webScriptNameForSelector: (SEL) sel
{
    return nil;
    (void) sel;
}

#pragma mark -
#pragma mark init

- (id) initWithController: (id) controller
{
    self = [super init];
    if (self)
	appController = controller;
    return self;
}

#pragma mark -
#pragma mark script communication methods

// tell the map to hide or drop a marker
- (void) adjustMapForLatitude: (NSString *) lat
		    longitude: (NSString *) lng
			 name: (NSString *) name;
{
    if (lat && lng) {
	NSArray* args = [NSArray arrayWithObjects: lat, lng, name, nil];
	[[webView windowScriptObject] callWebScriptMethod: @"addMarkerToMapAt"
					    withArguments: args];
    } else
	[[webView windowScriptObject] callWebScriptMethod: @"hideMarker"
					    withArguments: nil];
}

// called from javascript when a marker is placed on the map.
// The marker is at mapLat, mapLng.
- (void) reportPosition
{
    [appController updateLatitude: mapLat longitude: mapLng];
}

#pragma mark -
#pragma mark WebView load delegate

- (void)       webView: (WebView *) sender
  didClearWindowObject: (WebScriptObject *) windowObject
	      forFrame: (WebFrame *) frame
{
    // javascript will know this object as "controller".
    [windowObject setValue: self forKey: @"controller"];
    (void) sender;
    (void) frame;
}


@end
