//
//  GTController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface GTController : NSObject {
    IBOutlet NSTableView *tableView;
    IBOutlet NSImageView *imageWell;
    IBOutlet WebView *webView;
    NSMutableArray *images;
    NSString *webLat;
    NSString *webLng;
}

+ (BOOL) isSelectorExcludedFromWebScript: (SEL) selector;
+ (BOOL) isKeyExcludedFromWebScript: (const char *) property;
+ (NSString *) webScriptNameForSelector: (SEL) sel;

- (IBAction) showOpenPanel: (id) sender;
- (IBAction) saveLocations: (id) sender;
- (IBAction) revertToSaved: (id) sender;
- (IBAction) showPreferencePanel: (id) sender;

- (void) report;

@end
