//
//  GTMapView.m
//  GeoTag
//
//  Created by Marco S Hyman on 7/16/09.
//

#import "GTMapView.h"
#import "GTController.h"

@implementation GTMapView

@synthesize appController;
@synthesize mapLat;
@synthesize mapLng;
@synthesize hiddenMarker;

#pragma mark -
#pragma mark WebScripting Protocol methods

// only the report selector can be called from the script
+ (BOOL) isSelectorExcludedFromWebScript: (SEL) selector
{
    if (selector == @selector(reportPosition))
	return NO;
    return YES;
}

// the script has access to mapLat and mapLng variables
+ (BOOL) isKeyExcludedFromWebScript: (const char *) property
{
    if ((strcmp(property, "mapLat") == 0) ||
	(strcmp(property, "mapLng") == 0))
        return NO;
    return YES;
    
}

// no script-to-selector name translation needed
+ (NSString *) webScriptNameForSelector: (SEL) sel
{
    return nil;
}


#pragma mark -
#pragma mark script communication methods

// hide any existing marker
- (void) hideMarker: (NSString *) name;
{
    if (! [self isHiddenMarker]) {
        NSArray *args = @[name];
        [[self windowScriptObject] callWebScriptMethod: @"hideMarker"
                                         withArguments: args];
        [self setHiddenMarker: YES];
    }
}

// tell the map to drop a marker
- (void) adjustMapForLatitude: (CGFloat) lat
		    longitude: (CGFloat) lng
			 name: (NSString *) name;
{
    if (lat && lng) {
	NSString *latStr = [NSString stringWithFormat: @"%f", lat];
	NSString *lngStr = [NSString stringWithFormat: @"%f", lng];
	if ([self isHiddenMarker] ||
	    ! [[self mapLat] isEqualToString: latStr] ||
	    ! [[self mapLng] isEqualToString: lngStr]) {
	    NSArray* args =
		@[latStr, lngStr, name];
	    [[self windowScriptObject] callWebScriptMethod: @"addMarkerToMapAt"
					     withArguments: args];
	    [self setMapLat: latStr];
	    [self setMapLng: lngStr];
	    [self setHiddenMarker: NO];
	}
    }
}

// called from javascript when a marker is placed on the map.
// The marker is at mapLat, mapLng.
- (void) reportPosition
{
    [self setHiddenMarker: NO];
    [appController updateLatitude: [self mapLat] longitude: [self mapLng]];
}

#pragma mark -
#pragma mark Load initial map

- (void) awakeFromNib
{
    [self loadMap];
}

- (void) loadMap
{
    [self setFrameLoadDelegate: self];
    [[self mainFrame] loadRequest:
     [NSURLRequest requestWithURL:
      [NSURL fileURLWithPath:
	[[NSBundle mainBundle] pathForResource:@"map" ofType:@"html"]]]];
}

#pragma mark -
#pragma mark WebView frame load delegate method

- (void)       webView: (WebView *) sender
  didClearWindowObject: (WebScriptObject *) windowObject
	      forFrame: (WebFrame *) frame
{
    // javascript will know this object as "controller".
    [windowObject setValue: self forKey: @"controller"];
}


@end
