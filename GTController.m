//
//  GTController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import "GTController.h"
#import "ImageInfo.h"
#import "GTDefaultscontroller.h"


@implementation GTController

#pragma mark -
#pragma mark Startup and teardown

- (id) init
{
    if ((self = [super init])) {
	images = [[NSMutableArray alloc] init];

	// force app defaults and preferences initialization
	[GTDefaultsController class];
    }
    return self;
}

/*
 * This controller is set as the window deligate in IB so it will be
 * notified when the window is closing, letting it terminate the
 * app.
 */
- (void) windowWillClose: (NSNotification *) aNotification
{
    (void) aNotification;   
    [NSApp terminate: self];
}

#pragma mark -
#pragma mark IB Actions

/*
 * open the preference window
 */
- (IBAction) showPreferencePanel: (id) sender
{
    [[GTDefaultsController sharedPrefsWindowController] showWindow:nil];
    (void)sender;
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

#pragma mark -
#pragma mark tableView datasource functions

- (NSInteger) numberOfRowsInTableView: (NSTableView *) tv
{
    (void) tv;
    return [images count];
}

- (id) tableView: (NSTableView *) tv
objectValueForTableColumn: (NSTableColumn *) tableColumn
	     row: (NSInteger) row
{
    (void) tv;
    ImageInfo *imageInfo = [images objectAtIndex: row];
    SEL selector = NSSelectorFromString([tableColumn identifier]);
    return [imageInfo performSelector: selector];
}

#pragma mark -
#pragma mark tableView delegate functions

- (void) tableView: (NSTableView *) aTableView
   willDisplayCell: (id) aCell
    forTableColumn: (NSTableColumn *) aTableColumn
	       row: (NSInteger) rowIndex
{
    if (! [[images objectAtIndex: rowIndex] validImage])
	[aCell setTextColor: [NSColor grayColor]];
    (void) aTableView;
    (void) aTableColumn;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    (void) notification;
    NSInteger row = [tableView selectedRow];
    if (row == -1)
	return;
    NSLog(@"table view row %d selected", row);
    ;;;
}

@end
