//
//  GTController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import <Cocoa/Cocoa.h>

@interface GTController : NSObject {
    IBOutlet NSTableView *tableView;
}

- (IBAction) showOpenPanel: (id) sender;

@end
