//
//  PrefController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/17/09.
//

#import <Cocoa/Cocoa.h>

@interface PrefController : NSWindowController {
    IBOutlet NSPathControl *exiftoolPathController;
    IBOutlet NSImageView *badExiftoolPathIcon;
    IBOutlet NSView *exiftoolPathOpenAccessory;
    NSOpenPanel *exiftoolPathOpenPanel;
}

- (IBAction) setMakeBackupFiles: (id) sender;
- (IBAction) checkExiftoolValidity: (id) sender;
- (IBAction) resetExiftoolPath: (id) sender;

- (void) pathCell: (NSPathCell *) pathCell
    willDisplayOpenPanel: (NSOpenPanel *) openPanel;

@end
