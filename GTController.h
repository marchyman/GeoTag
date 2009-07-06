//
//  GTController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "SSTableView.h"

@interface GTController : NSObject {
    IBOutlet SSTableView *tableView;
    IBOutlet NSImageView *imageWell;
    IBOutlet WebView *webView;
    IBOutlet NSProgressIndicator *progressIndicator;
    
    NSMutableArray *images;
    NSUndoManager *undoManager;
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
- (IBAction) cut: (id)sender;
- (IBAction) copy: (id) sender;
- (IBAction) paste: (id) sender;
- (IBAction) delete: (id) sender;

- (void) report;

- (NSProgressIndicator *) progressIndicator;

@end
