//
//  GTController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import "GTController.h"


@implementation GTController

- (id) init
{
    if ((self = [super init])) {
	;;;
    }
    return self;
}

/*
 * open/load images into the table view for processing
 */
- (void) openPanelDidEnd: (NSOpenPanel *) openPanel
	      returnCode: (int) returnCode
	     contextInfo: (void *) x
{
    if (returnCode == NSOKButton) {
	NSString *path = [openPanel filename];
	NSLog(@"open panel path: %@", path);
	;;;
	/*
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
	[stretchView setImage:image];
	[image release];
	 */
    }
}

- (IBAction) showOpenPanel: (id) sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel beginSheetForDirectory:nil
			     file:nil
		   modalForWindow:[tableView window]
		    modalDelegate:self
		   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
		      contextInfo:NULL];
}

/*
 * table view delegated functions
 */
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
    ;;;
    return 0;
}

- (id) tableView: (NSTableView *) tv
objectValueForTableColumn: (NSTableColumn *) tableColumn
	     row: (int) row
{
    ;;;
    return nil;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    int row = [tableView selectedRow];
    if (row == -1)
	return;
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
