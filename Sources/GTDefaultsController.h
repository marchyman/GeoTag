//
//  GTDefaultsController.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/18/09.
//

#import "DBPrefsWindowController.h"

extern NSString * const SSExiftoolPathKey;
extern NSString * const SSMakeBackupFilesKey;

@interface GTDefaultsController : DBPrefsWindowController

@property IBOutlet NSView *generalPreferenceView;

+ (NSString *) exiftoolPath;
+ (BOOL) makeBackupFiles;

- (IBAction) checkExiftoolValidity: (id) sender;
- (IBAction) resetExiftoolPath: (id) sender;

- (void)      pathCell: (NSPathCell *) pathCell
  willDisplayOpenPanel: (NSOpenPanel *) openPanel;

@end
