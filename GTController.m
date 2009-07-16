//
//  GTController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import "GTController.h"
#import "ImageInfo.h"
#import "GTDefaultscontroller.h"

@interface GTController ()
- (void) adjustMapViewForRow: (NSInteger) row;
- (void) updateLocationForImageAtRow: (NSInteger) row
			    latitude: (NSString *) lat
			   longitude: (NSString *) lng
			    modified: (BOOL) mod;
- (BOOL) isDuplicatePath: (NSString *) path;
- (BOOL) isValidImageAtRow: (NSInteger) row;
- (NSInteger) showProgressIndicator;
- (void) hideProgressIndicator: (NSInteger) row;
@end


@implementation GTController

#pragma mark -
#pragma mark Startup and teardown

- (id) init
{
    if ((self = [super init])) {
	images = [[NSMutableArray alloc] init];
	undoManager = [[NSUndoManager alloc] init];
	
	// force app defaults and preferences initialization
	[GTDefaultsController class];
    }
    return self;
}

- (void) awakeFromNib
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    [NSApp setDelegate: self];
    [tableView registerForDraggedTypes:
     [NSArray arrayWithObject: NSFilenamesPboardType]];
    
    // mapview init
    [mapView setAppController: self];
    [mapView loadMap];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) sender
{
    return YES;
    (void) sender;
}

/*
 * If there are unsaved changes put up an alert sheet asking
 * what to do and return NO.   The final action will depend
 * upon what button the user selects.
 */
- (void) alertEnded: (NSAlert *) alert
	   withCode: (NSInteger) choice
	    context: (void *) context
{
    NSWindow *window = (NSWindow *) context;
    switch (choice) {
	case NSAlertFirstButtonReturn:
	    // Save
	    [self saveLocations: self];
	    break;
	case NSAlertSecondButtonReturn:
	    // Cancel
	    return;
	default:
	    // Don't save
	    break;
    }
    [window setDocumentEdited: NO];
    [window close];
    (void) alert;
}

- (BOOL) saveOrDontSave: (NSWindow *) window
{
    if ([window isDocumentEdited]) {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle: NSLocalizedString(@"SAVE", @"Save")];
	[alert addButtonWithTitle: NSLocalizedString(@"CANCEL", @"Cancel")];
	[alert addButtonWithTitle: NSLocalizedString(@"DONT_SAVE", @"Don't Save")];
	[alert setMessageText: NSLocalizedString(@"UNSAVED_TITLE", @"Unsaved Changes")];
	[alert setInformativeText: NSLocalizedString(@"UNSAVED_DESC", @"Unsaved Changes")];
	[alert beginSheetModalForWindow: window
			  modalDelegate: self
			 didEndSelector: @selector(alertEnded:withCode:context:)
			    contextInfo: window];
	return NO;
    }
    return YES;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) app
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    if ([self saveOrDontSave: [app mainWindow]])
	return NSTerminateNow;
    return NSTerminateLater;
}

#pragma mark -
#pragma mark accessors

- (NSUndoManager *) undoManager
{
    return undoManager;
}

- (NSProgressIndicator *) progressIndicator
{
    return progressIndicator;
}

#pragma mark -
#pragma mark window delegate functions

- (NSUndoManager *) windowWillReturnUndoManager: (NSWindow *) window
{
    return [self undoManager];
    (void) window;
}

- (BOOL) windowShouldClose: (id) window
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return [self saveOrDontSave: window];
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
 * open dialog box.  Don't allow duplicate paths.  Spit out a
 * notification if some files could not be opened.
 */

- (IBAction) showOpenPanel: (id) sender
{
    BOOL reloadNeeded = NO;
    BOOL showWarning = NO;

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: YES];
    [panel setCanChooseFiles: YES];
    [panel setCanChooseDirectories: NO];
    NSInteger result = [panel runModalForDirectory: nil file: nil types: nil];
    if (result == NSOKButton) {
	// this may take a while, let the user know we're busy
	NSInteger row = [self showProgressIndicator];
	NSArray *filenames = [panel filenames];
	for (NSString *path in filenames) {
	    if (! [self isDuplicatePath: path]) {
		[images addObject: [ImageInfo imageInfoWithPath: path]];
		reloadNeeded = YES;
	    } else
		showWarning = YES;
	}
	[self hideProgressIndicator: row];

	if (reloadNeeded)
	    [tableView reloadData];
	if (showWarning) {
	    NSAlert *alert = [[NSAlert alloc] init];
	    [alert addButtonWithTitle: NSLocalizedString(@"CLOSE", @"Close")];
	    [alert setMessageText: NSLocalizedString(@"WARN_TITLE", @"Files not opened")];
	    [alert setInformativeText: NSLocalizedString(@"WARN_DESC", @"Files not opened")];
	    [alert runModal];
	}
    }
    (void) sender;
}

/*
 * Update any images that had a new location assigned.
 */
- (IBAction) saveLocations: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    NSInteger row = [self showProgressIndicator];
    for (ImageInfo *image in images)
	[image saveLocation];
    [[tableView window] setDocumentEdited: NO];
    // can not undo past a save
    [[self undoManager] removeAllActions];
    [self hideProgressIndicator: row];
    (void) sender;
}

/*
 *
 */
- (IBAction) revertToSaved: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    for (ImageInfo *image in images)
	[image revertLocation];
    [[tableView window] setDocumentEdited: NO];
    [[self undoManager] removeAllActions];
    [tableView reloadData];
    (void) sender;
}

- (IBAction) cut: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    [self copy: self];
    [self delete: self];
    (void) sender;
}

- (IBAction) copy: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    NSInteger row = [tableView selectedRow];
    if ([self isValidImageAtRow: row]) {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
		   owner: self];
	[pb setString: [[images objectAtIndex: row] stringRepresentation]
	      forType: NSStringPboardType];
    }
    (void) sender;
}

- (IBAction) paste: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    NSInteger row = [tableView selectedRow];
    if ([self isValidImageAtRow: row]) {
	NSString *latitude;
	NSString *longitude;
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	if ([[pb types] containsObject: NSStringPboardType]) {
	    NSString *val = [pb stringForType: NSStringPboardType];
	    if ([[images objectAtIndex: row]  convertFromString: val
							    lat: &latitude
							    lng: &longitude]) {
		[self updateLocationForImageAtRow: row
					 latitude: latitude
					longitude: longitude
					 modified: YES];
		[self adjustMapViewForRow: row];
	    }
	    
	}
    }
    (void) sender;
}

- (IBAction) delete: (id) sender
{
    NSInteger row = [tableView selectedRow];
    if ([self isValidImageAtRow: row]) {
	[self updateLocationForImageAtRow: row
				 latitude: nil
				longitude: nil
				 modified: YES];
	[self adjustMapViewForRow: row];
    }
    (void) sender;  
}

- (IBAction) clear: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    if (! [[tableView window] isDocumentEdited]) {
	images = [[NSMutableArray alloc] init];
	[[self undoManager] removeAllActions];
	[tableView reloadData];
    }
    (void) sender;
}

#pragma mark -
#pragma mark menu item validation

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
    SEL action = [item action];
    
    if (action == @selector(saveLocations:) ||
	action == @selector(revertToSaved:))
	return [[tableView window] isDocumentEdited];
    if (action == @selector(copy:) ||
	action == @selector(cut:) ||
	action == @selector(paste:) ||
	action == @selector(delete:))
	return [self isValidImageAtRow: [tableView selectedRow]];
    if (action == @selector(clear:))
	return ([images count] > 0) &&
	       (! [[tableView window] isDocumentEdited]);
    return YES;
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
#pragma mark tableView Drop functions

// Drops are only allowed at the end of the table

- (NSDragOperation) tableView: (NSTableView *) aTableView
		 validateDrop: (id < NSDraggingInfo >) info
		  proposedRow: (NSInteger) row
	proposedDropOperation: (NSTableViewDropOperation) op
{
    BOOL dropValid = YES;

    NSPasteboard* pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject: NSFilenamesPboardType]) {
	if (row < [aTableView numberOfRows])
	    dropValid = NO;
	else {
	    NSArray *pathArray =
		    [pboard propertyListForType:NSFilenamesPboardType];
	    NSFileManager *fileManager = [NSFileManager defaultManager];
	    BOOL dir;
	    for (NSString *path in pathArray) {
		[fileManager fileExistsAtPath: path isDirectory: &dir];
		if (dir || [self isDuplicatePath: path])
		    dropValid = NO;
	    }
	}
    }
    if (dropValid)
	return NSDragOperationLink;

    return NSDragOperationNone;
    (void) aTableView;
    (void) row;
    (void) op;
}


- (BOOL) tableView: (NSTableView *) aTableView
	acceptDrop: (id <NSDraggingInfo>) info
	       row: (NSInteger) row
     dropOperation: (NSTableViewDropOperation) op 
{
    BOOL dropAccepted = NO;
    NSPasteboard* pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject: NSFilenamesPboardType]) {
	NSArray *pathArray = [pboard propertyListForType:NSFilenamesPboardType];
	for (NSString *path in pathArray) {
	    if (! [self isDuplicatePath: path]) {
		[images addObject: [ImageInfo imageInfoWithPath: path]];
		dropAccepted = YES;
	    }
	}
    }
    if (dropAccepted) {
	[tableView reloadData];
	[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
	       byExtendingSelection: NO];
    }

    return dropAccepted;

    (void) aTableView;
    (void) op;
} 


#pragma mark -
#pragma mark tableView delegate functions

- (void) tableView: (NSTableView *) aTableView
   willDisplayCell: (id) aCell
    forTableColumn: (NSTableColumn *) aTableColumn
	       row: (NSInteger) rowIndex
{
    if ([aCell respondsToSelector:@selector(setTextColor:)]) {
	NSColor *textColor;
	if ([self isValidImageAtRow: rowIndex])
	    textColor = [NSColor blackColor];
	else
	    textColor = [NSColor grayColor];
    
	[aCell setTextColor: textColor];
    }

    (void) aTableView;
    (void) aTableColumn;
}

- (BOOL) tableView: (NSTableView *) aTableView
   shouldSelectRow: (NSInteger) rowIndex
{
    return [self isValidImageAtRow: rowIndex];
    (void) aTableView;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    // NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    NSInteger row = [tableView selectedRow];
    NSImage *image = nil;
    if (row != -1) {
	image = [[NSImage alloc] initWithContentsOfFile:
		 [[images objectAtIndex: row] path]];
	[self adjustMapViewForRow: row];
    }
    [imageWell setImage: image];
    (void) notification;
}

- (NSString *) tableView: (NSTableView *) tv
	  toolTipForCell: (NSCell *) aCell
		    rect: (NSRectPointer) rect
	     tableColumn: (NSTableColumn *) aTableColumn
		     row: (NSInteger) row
	   mouseLocation: (NSPoint) mouseLocation
{
    // NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    if ([[aTableColumn identifier] isEqual: @"name"])
	return [[images objectAtIndex: row] path];
    return nil;
    (void) tv;
    (void) aCell;
    (void) rect;
    (void) mouseLocation;
}

#pragma mark -
#pragma mark web view and scripting methods

/*
 * If there is a latitude and longitude associated with the
 * data at the given row center the map and drop a marker
 * at that location.
 */
- (void) adjustMapViewForRow: (NSInteger) row
{
    ImageInfo * image = [images objectAtIndex: row];
    if (image)
	[mapView adjustMapForLatitude: [image latitude]
			    longitude: [image longitude]
				 name: [image name]];
    else
	[mapView hideMarker];
}

// called from the map view when a marker is moved.
- (void) updateLatitude: (NSString *) lat
	      longitude: (NSString *) lng
{
    NSInteger row = [tableView selectedRow];
    if (row != -1)
	[self updateLocationForImageAtRow: row
				 latitude: lat
				longitude: lng
				 modified: YES];
}

#pragma mark -
#pragma mark progress indicator control
- (NSInteger) showProgressIndicator
{
    NSInteger row = [tableView selectedRow];
    if (row != -1)
	[tableView deselectRow: row];
    NSProgressIndicator* pi = [self progressIndicator];
    [pi setUsesThreadedAnimation:YES];
    [pi setHidden:NO];
    [pi startAnimation:self];
    [pi display];
    return row;
}

- (void) hideProgressIndicator: (NSInteger) row
{
    NSProgressIndicator* pi = [self progressIndicator];
    [pi stopAnimation:self];
    [pi setHidden:YES];
    
    if (row != -1)
	[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
	       byExtendingSelection: NO];
}

#pragma mark -
#pragma mark helper methods

// location update with undo/redo support
- (void) updateLocationForImageAtRow: (NSInteger) row
			    latitude: (NSString *) lat
			   longitude: (NSString *) lng
			    modified: (BOOL) mod
{
    ImageInfo *image = [images objectAtIndex: row];
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget: self]
	updateLocationForImageAtRow: row
			   latitude: [image latitude]
			  longitude: [image longitude]
			   modified: [[tableView window] isDocumentEdited]];
    [image setLocationToLat: lat lng: lng];
    //  Needed with undo/redo to force mapView update
    // (mapView updated in tableViewSelectionDidChange)
    if ([undo isUndoing] || [undo isRedoing]) {
	[tableView deselectRow: row];
	[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
	       byExtendingSelection: NO];
    }
    [tableView setNeedsDisplayInRect: [tableView rectOfRow: row]];
    [[tableView window] setDocumentEdited: mod];
}

- (BOOL) isDuplicatePath: (NSString *) path
{
    for (ImageInfo *image in images) {
	if ([[image path] isEqualToString: path]) {
	    NSLog(@"duplicatePath: %@", path);
	    return YES;
	}
    }
    return NO;
}

- (BOOL) isValidImageAtRow: (NSInteger) row
{
    if ((row >= 0) && (row < (NSInteger) [images count])) {
	ImageInfo *anImage = [images objectAtIndex: row];
	return [anImage validImage];
    }
    return NO;
}

@end
