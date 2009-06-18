//
//  PrefController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/17/09.
//

#import <Cocoa/Cocoa.h>

extern NSString * const SSExiftoolPathKey;

@interface PrefController : NSWindowController {
    IBOutlet NSTextField *exiftoolPath;
}

- (IBAction) chooseExiftoolPath: (id) sender;

- (NSTextField *) exiftoolPath;
- (void) setExiftoolPath: (NSTextField *) newExiftoolPath;

@end
