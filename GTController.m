//
//  GTController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import "GTController.h"
#import "ImageInfo.h"

@implementation GTController

- (id) init
{
    if ((self = [super init])) {
	images = [[NSMutableArray alloc] init];
    }
    return self;
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
