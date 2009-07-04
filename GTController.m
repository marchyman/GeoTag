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
    
    // webview init
    [[webView mainFrame] loadRequest:
     [NSURLRequest requestWithURL:
      [NSURL fileURLWithPath:
       [[NSBundle mainBundle] pathForResource:@"map" ofType:@"html"]]]];
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
 * open dialog box.  Don't allow duplicate paths.
 */
- (IBAction) showOpenPanel: (id) sender
{
    BOOL reloadNeeded = NO;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: YES];
    [panel setCanChooseFiles: YES];
    [panel setCanChooseDirectories: NO];
    NSInteger result = [panel runModalForDirectory: nil file: nil types: nil];
    if (result == NSOKButton) {
	NSArray *filenames = [panel filenames];
	for (NSString *path in filenames) {
	    if (! [self isDuplicatePath: path]) {
		[images addObject: [ImageInfo imageInfoWithPath: path]];
		reloadNeeded = YES;
	    }
	}
	if (reloadNeeded)
	    [tableView reloadData];
    }
    (void) sender;
}

/*
 * Update any images that had a new location assigned.
 */
- (IBAction) saveLocations: (id) sender
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    for (ImageInfo *image in images)
	[image saveLocation];
    [[tableView window] setDocumentEdited: NO];
    // can not undo past a save
    [[self undoManager] removeAllActions];
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

#pragma mark -
#pragma mark menu item validation

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
    SEL action = [item action];
    
    if (action == @selector(saveLocations:) ||
	action == @selector(revertToSaved:))
	return [[tableView window] isDocumentEdited];
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
	ImageInfo *anImage = [images objectAtIndex: rowIndex];
	NSColor *textColor;

	if ([anImage validImage])
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
    return [[images objectAtIndex: rowIndex] validImage];
    (void) aTableView;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
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

#pragma mark -
#pragma mark map view control functions

/*
 * If there is a latitude and longitude associated with the
 * data at the given row center the map and drop a marker
 * at that location.
 */
- (void) adjustMapViewForRow: (NSInteger) row
{
    ImageInfo * image = [images objectAtIndex: row];
    NSString *lat = [image latitude];
    NSString *lng = [image longitude];
    NSLog(@"%@ received %@ - lat %@ lng %@", self, NSStringFromSelector(_cmd),
	  lat, lng);
    
    if (lat && lng) {
	NSArray* args = [NSArray arrayWithObjects: lat, lng,
			 [image name], nil];
	[[webView windowScriptObject] callWebScriptMethod: @"addMarkerToMapAt"
					    withArguments: args];
    } else
	[[webView windowScriptObject] callWebScriptMethod: @"hideMarker"
					    withArguments: nil];

}

#pragma mark -
#pragma mark webView delegate functions

- (void) webView: (WebView *) sender
didClearWindowObject: (WebScriptObject *) windowObject
	forFrame: (WebFrame *) frame
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    // javascript will know this object as "controller".
    [windowObject setValue: self forKey: @"controller"];
    (void) sender;
    (void) frame;
}

#pragma mark -
#pragma mark WebScripting functions
+ (BOOL) isSelectorExcludedFromWebScript: (SEL) selector
{
    if (selector == @selector(report))
	return NO;
    return YES;
}

+ (BOOL) isKeyExcludedFromWebScript: (const char *) property
{
    if ((strcmp(property, "webLat") == 0) ||
	(strcmp(property, "webLng") == 0))
        return NO;
    return YES;
    
}

+ (NSString *) webScriptNameForSelector: (SEL) sel
{
    NSLog(@"%@ received %@ with sel='%@'", self, NSStringFromSelector(_cmd),
	  NSStringFromSelector(sel));
    return nil;
}


// make this call a function that has all the params to simplify
// undo.  Include isDocumentEdited to get it completely correct.

- (void) report
{
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    NSLog(@"webLat = %@, webLng = %@", webLat, webLng);
    NSInteger row = [tableView selectedRow];
    if (row != -1)
	[self updateLocationForImageAtRow: row
				 latitude: webLat
				longitude: webLng
				modified: [[tableView window] isDocumentEdited]];
}

#pragma mark -
#pragma mark helper methods

/*
 * update stuff in one place for ease of undo/redo
 */
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
    [tableView deselectRow: row];
    [image setLocationToLat: lat lng: lng];
    // webView updated in tableViewSelectionDidChange
    [tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
	   byExtendingSelection: NO];
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

@end
