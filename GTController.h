//
//  GTController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import <Cocoa/Cocoa.h>
@class PrefController;

@interface GTController : NSObject {
    IBOutlet NSTableView *tableView;
    NSMutableArray *images;
    PrefController *prefController;
}

- (IBAction) showOpenPanel: (id) sender;
- (IBAction) showPreferencePanel: (id) sender;

@end
