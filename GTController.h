//
//  GTController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "GTTableView.h"
#import "GTMapView.h"

@interface GTController : NSObject {
    IBOutlet GTTableView *tableView;
    IBOutlet NSImageView *imageWell;
    IBOutlet GTMapView *mapView;
    IBOutlet NSProgressIndicator *progressIndicator;
    
    NSMutableArray *images;
    NSUndoManager *undoManager;
}

- (IBAction) showOpenPanel: (id) sender;
- (IBAction) saveLocations: (id) sender;
- (IBAction) revertToSaved: (id) sender;
- (IBAction) showPreferencePanel: (id) sender;
- (IBAction) cut: (id)sender;
- (IBAction) copy: (id) sender;
- (IBAction) paste: (id) sender;
- (IBAction) delete: (id) sender;
- (IBAction) clear: (id) sender;

- (NSProgressIndicator *) progressIndicator;
- (void) updateLatitude: (NSString *) lat
	      longitude: (NSString *) lng;

@end
