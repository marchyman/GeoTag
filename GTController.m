//
//  GTController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import "GTController.h"
#import "ImageInfo.h"
#import "PrefController.h"

@implementation GTController

/*
 * Would be better to initialze this from a UserDefaults.plist in the
 * bundle.
 */
+ (void) initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
				 dictionaryWithObject: @"/usr/bin/exiftool"
				 forKey: SSExiftoolPathKey];
    [defaults registerDefaults: appDefaults];
}

- (id) init
{
    if ((self = [super init])) {
	images = [[NSMutableArray alloc] init];
    }
    return self;
}

/*
 * instantiate, if necessary, and open the preference window
 */
- (IBAction) showPreferencePanel: (id) sender
{
    (void) sender;
    if (! prefController) 
	prefController = [[PrefController alloc] init];
    [prefController showWindow: self];
}

/*
 * Let the user select images or directories of images from an
 * open dialog box.
 */
- (IBAction) showOpenPanel: (id) sender
{
    (void) sender;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSInteger result;

    [panel setAllowsMultipleSelection: YES];
    [panel setCanChooseFiles: YES];
    [panel setCanChooseDirectories: YES];
    result = [panel runModalForDirectory: nil file: nil types: nil];
    if (result == NSOKButton) {
	NSArray *filenames = [panel filenames];
	for (NSString *path in filenames) {
	    NSLog(@"open panel path: %@", path);
	    [images addObject: [ImageInfo imageInfoWithPath: path]];
	}
	[tableView reloadData];
    }
}

/*
 * table view delegated functions
 */
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
    (void) tv;
    return [images count];
}

- (id) tableView: (NSTableView *) tv
objectValueForTableColumn: (NSTableColumn *) tableColumn
	     row: (int) row
{
    (void) tv;
    ImageInfo *imageInfo = [images objectAtIndex: row];
    SEL selector = NSSelectorFromString([tableColumn identifier]);
    return [imageInfo performSelector: selector];
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    (void) notification;
    int row = [tableView selectedRow];
    if (row == -1)
	return;
    NSLog(@"table view row %d selected", row);
    ;;;
}

/*
 * This view is set as the windows deligate in IB so it will be
 * notified when the window is closing, letting it terminate the
 * app.
 */
- (void) windowWillClose: (NSNotification *) aNotification
{
    (void) aNotification;   
    [NSApp terminate: self];
}

@end
