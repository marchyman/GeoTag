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
}

- (IBAction) showOpenPanel: (id) sender;
- (IBAction) showPreferencePanel: (id) sender;
- (IBAction) addImageFromView: (id) sender;

@end
