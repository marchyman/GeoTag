//
//  PrefController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/17/09.
//

#import "PrefController.h"
#import "GTDefaults.h"

@implementation PrefController

#pragma mark -
#pragma mark init

- (id)init
{
    return [super initWithWindowNibName:@"Preferences"];
}

#pragma mark -
#pragma mark delegate methods

- (IBAction) setMakeBackupFiles: (id) sender
{
    (void) sender;
}

- (IBAction) checkExiftoolValidity: (id) sender
{
    (void) sender;
}

- (IBAction) resetExiftoolPath: (id) sender
{
    [[NSUserDefaults standardUserDefaults]
	removeObjectForKey:SSExiftoolPathKey];
}

- (void) pathCell: (NSPathCell *) pathCell
    willDisplayOpenPanel: (NSOpenPanel *) openPanel
{
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    // [openPanel setAccessoryView:exiftoolPathOpenAccessory];
    
    exiftoolPathOpenPanel = openPanel;
}

- (void) windowDidLoad
{
    ;;;
    NSLog(@"windowDidLoad");
}

@end
