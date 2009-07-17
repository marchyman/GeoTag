//
//  GTController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/14/09.
//

#import "GTController.h"
#import "GTDefaultscontroller.h"

#if GTDEBUG == 0
#define NSLog(...)
#endif

@interface GTController ()
- (NSInteger) showProgressIndicator;
- (void) hideProgressIndicator: (NSInteger) row;
- (NSProgressIndicator *) progressIndicator;
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
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) sender
{
    return YES;
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

- (BOOL) windowShouldClose: (id) window
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return [self saveOrDontSave: window];
}

#pragma mark -
#pragma mark image related methods

- (ImageInfo *) imageAtIndex: (NSInteger) ix
{
    return [images objectAtIndex: ix];
}

- (BOOL) isValidImageAtIndex: (NSInteger) ix
{
    if ((ix >= 0) && (ix < (NSInteger) [images count]))
	return [[self imageAtIndex: ix] validImage];
    return NO;
}

- (BOOL) addImageForPath: (NSString *) path
{
    if (! [self isDuplicatePath: path]) {
	[images addObject: [ImageInfo imageInfoWithPath: path]];
	return YES;
    }
    return NO;
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

#pragma mark -
#pragma mark undo related methods

- (NSUndoManager *) undoManager
{
    return undoManager;
}

- (NSUndoManager *) windowWillReturnUndoManager: (NSWindow *) window
{
    return [self undoManager];
}

#pragma mark -
#pragma mark IB Actions

/*
 * open the preference window
 */
- (IBAction) showPreferencePanel: (id) sender
{
    [[GTDefaultsController sharedPrefsWindowController] showWindow:nil];
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
    [[NSApp mainWindow] setDocumentEdited: NO];
    // can not undo past a save
    [[self undoManager] removeAllActions];
    [self hideProgressIndicator: row];
}

/*
 *
 */
- (IBAction) revertToSaved: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    for (ImageInfo *image in images)
	[image revertLocation];
    [[NSApp mainWindow] setDocumentEdited: NO];
    [[self undoManager] removeAllActions];
    [tableView reloadData];
}

- (IBAction) clear: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    if (! [[NSApp mainWindow] isDocumentEdited]) {
	images = [[NSMutableArray alloc] init];
	[[self undoManager] removeAllActions];
	[tableView reloadData];
    }
}

#pragma mark -
#pragma mark menu item validation

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
    SEL action = [item action];
    
    if (action == @selector(saveLocations:) ||
	action == @selector(revertToSaved:))
	return [[NSApp mainWindow] isDocumentEdited];
    if (action == @selector(clear:))
	return ([images count] > 0) &&
	       (! [[NSApp mainWindow] isDocumentEdited]);
    return YES;
}

#pragma mark -
#pragma mark tableView datasource and drop methods

- (NSInteger) numberOfRowsInTableView: (NSTableView *) tv
{
    return [images count];
}

- (id)            tableView: (NSTableView *) tv
  objectValueForTableColumn: (NSTableColumn *) tableColumn
			row: (NSInteger) row
{
    ImageInfo *imageInfo = [self imageAtIndex: row];
    SEL selector = NSSelectorFromString([tableColumn identifier]);
    return [imageInfo performSelector: selector];
}

// Drops are only allowed at the end of the table
- (NSDragOperation) tableView: (NSTableView *) aTableView
		 validateDrop: (id < NSDraggingInfo >) info
		  proposedRow: (NSInteger) row
	proposedDropOperation: (NSTableViewDropOperation) op
{
    BOOL dropValid = YES;
    
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
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
}


- (BOOL) tableView: (NSTableView *) aTableView
	acceptDrop: (id <NSDraggingInfo>) info
	       row: (NSInteger) row
     dropOperation: (NSTableViewDropOperation) op 
{
    BOOL dropAccepted = NO;
    
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    NSPasteboard* pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject: NSFilenamesPboardType]) {
	NSArray *pathArray = [pboard propertyListForType:NSFilenamesPboardType];
	for (NSString *path in pathArray)
	    if ([self addImageForPath: path])
		dropAccepted = YES;
    }
    if (dropAccepted) {
	[tableView reloadData];
	[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
	  byExtendingSelection: NO];
    }

    return dropAccepted;
} 

#pragma mark -
#pragma mark image well control

- (void) showImageForIndex: (NSInteger) ix
{
    NSImage *image = nil;
    if (ix != -1) {
	image = [[NSImage alloc] initWithContentsOfFile:
		 [[self imageAtIndex: ix] path]];
	[self adjustMapViewForRow: ix];
    }
    [imageWell setImage: image];
    
}

#pragma mark -
#pragma mark map view control

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

- (NSProgressIndicator *) progressIndicator
{
    return progressIndicator;
}

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
#pragma mark undoable image update

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
			   modified: [[NSApp mainWindow] isDocumentEdited]];
    [image setLocationToLatitude: lat longitude: lng];
    //  Needed with undo/redo to force mapView update
    // (mapView updated in tableViewSelectionDidChange)
    if ([undo isUndoing] || [undo isRedoing]) {
	[tableView deselectRow: row];
	[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
	       byExtendingSelection: NO];
    }
    [tableView setNeedsDisplayInRect: [tableView rectOfRow: row]];
    [[NSApp mainWindow] setDocumentEdited: mod];
}

@end
