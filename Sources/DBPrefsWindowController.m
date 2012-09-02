//
//  DBPrefsWindowController.m
//

#import "DBPrefsWindowController.h"


@implementation DBPrefsWindowController

#pragma mark -
#pragma mark Class Methods


+ (DBPrefsWindowController *)sharedPrefsWindowController
{
    static DBPrefsWindowController *_sharedPrefsWindowController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPrefsWindowController =
            [[self alloc] initWithWindowNibName:[self nibName]];
    });
    return _sharedPrefsWindowController;
}

// Subclasses can override this to use a nib with a different name.
+ (NSString *)nibName
{
   return @"Preferences";
}

#pragma mark -
#pragma mark Setup & Teardown

// -initWithWindow: is the designated initializer for NSWindowController.
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:nil];
    if (self != nil) {
        // Set up an array and some dictionaries to keep track
        // of the views we'll be displaying.
        toolbarIdentifiers = [[NSMutableArray alloc] init];
        toolbarViews = [[NSMutableDictionary alloc] init];
        toolbarItems = [[NSMutableDictionary alloc] init];

        // Set up an NSViewAnimation to animate the transitions.
        viewAnimation = [[NSViewAnimation alloc] init];
        [viewAnimation setAnimationBlockingMode:NSAnimationNonblocking];
        [viewAnimation setAnimationCurve:NSAnimationEaseInOut];
        [viewAnimation setDelegate:self];
        [self setCrossFade:YES];
        [self setShiftSlowsAnimation:YES];
    }
    return self;
}

- (void)windowDidLoad
{
    // Create a new window to display the preference views.
    // If the developer attached a window to this controller
    // in Interface Builder, it gets replaced with this one.
    NSWindow *window =
        [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1000,1000)
                                    styleMask:(NSTitledWindowMask |
                                               NSClosableWindowMask |
                                               NSMiniaturizableWindowMask)
                                      backing:NSBackingStoreBuffered
                                        defer:YES];
    [self setWindow:window];
    contentSubview = [[NSView alloc] initWithFrame:[[[self window] contentView] frame]];
    [contentSubview setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
    [[[self window] contentView] addSubview:contentSubview];
    [[self window] setShowsToolbarButton:NO];
}

#pragma mark -
#pragma mark Configuration

- (void)setupToolbar
{
    // Subclasses must override this method to add items to the
    // toolbar by calling -addView:label: or -addView:label:image:.
}

- (void)addView:(NSView *)view label:(NSString *)label
{
    [self addView:view
            label:label
            image:[NSImage imageNamed:label]];
}

- (void)addView:(NSView *)view label:(NSString *)label image:(NSImage *)image
{
    NSAssert (view != nil,
              @"Attempted to add a nil view when calling -addView:label:image:.",
              nil);
	
    NSString *identifier = [label copy];
	
    [toolbarIdentifiers addObject:identifier];
    toolbarViews[identifier] = view;
	
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    [item setLabel:label];
    [item setImage:image];
    [item setTarget:self];
    [item setAction:@selector(toggleActivePreferenceView:)];
	
    toolbarItems[identifier] = item;
}

#pragma mark -
#pragma mark Overriding Methods

- (IBAction)showWindow:(id)sender
{
    // This forces the resources in the nib to load.
    (void)[self window];

    // Clear the last setup and get a fresh one.
    [toolbarIdentifiers removeAllObjects];
    [toolbarViews removeAllObjects];
    [toolbarItems removeAllObjects];
    [self setupToolbar];

    NSAssert (([toolbarIdentifiers count] > 0),
	      @"No items were added to the toolbar in -setupToolbar.", nil);

    if ([[self window] toolbar] == nil) {
        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"DBPreferencesToolbar"];
        [toolbar setAllowsUserCustomization:NO];
        [toolbar setAutosavesConfiguration:NO];
        [toolbar setSizeMode:NSToolbarSizeModeDefault];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
        [toolbar setDelegate:self];
        [[self window] setToolbar:toolbar];
    }
	
    NSString *firstIdentifier = toolbarIdentifiers[0];
    [[[self window] toolbar] setSelectedItemIdentifier:firstIdentifier];
    [self displayViewForIdentifier:firstIdentifier animate:NO];
	
    [[self window] center];

    [super showWindow:sender];
}

#pragma mark -
#pragma mark Toolbar

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return toolbarIdentifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return toolbarIdentifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return toolbarIdentifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)identifier
 willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    return toolbarItems[identifier];
}

- (void)toggleActivePreferenceView:(NSToolbarItem *)toolbarItem
{
    [self displayViewForIdentifier:[toolbarItem itemIdentifier] animate:YES];
}

- (void)displayViewForIdentifier:(NSString *)identifier animate:(BOOL)animate
{	
    // Find the view we want to display.
    NSView *newView = toolbarViews[identifier];

    // See if there are any visible views.
    NSView *oldView = nil;
    if ([[contentSubview subviews] count] > 0) {
        // Get a list of all of the views in the window. Usually at this
        // point there is just one visible view. But if the last fade
        // hasn't finished, we need to get rid of it now before we move on.
        NSEnumerator *subviewsEnum = [[contentSubview subviews] reverseObjectEnumerator];
		
        // The first one (last one added) is our visible view.
        oldView = [subviewsEnum nextObject];
		
        // Remove any others.
        NSView *reallyOldView = nil;
        while ((reallyOldView = [subviewsEnum nextObject]) != nil) {
            [reallyOldView removeFromSuperviewWithoutNeedingDisplay];
        }
    }
	
    if (![newView isEqualTo:oldView]) {
        NSRect frame = [newView bounds];
        frame.origin.y = NSHeight([contentSubview frame]) - NSHeight([newView bounds]);
        [newView setFrame:frame];
        [contentSubview addSubview:newView];
        [[self window] setInitialFirstResponder:newView];

        if (animate && [self crossFade])
            [self crossFadeView:oldView withView:newView];
        else {
            [oldView removeFromSuperviewWithoutNeedingDisplay];
            [newView setHidden:NO];
            [[self window] setFrame:[self frameForView:newView] display:YES animate:animate];
        }

        [[self window] setTitle:[toolbarItems[identifier] label]];
    }
}

#pragma mark -
#pragma mark Cross-Fading Methods

- (void)crossFadeView:(NSView *)oldView withView:(NSView *)newView
{
    [viewAnimation stopAnimation];
	
    if ([self shiftSlowsAnimation] && [[[self window] currentEvent] modifierFlags] & NSShiftKeyMask)
        [viewAnimation setDuration:1.25];
    else
        [viewAnimation setDuration:0.25];
	
    NSDictionary *fadeOutDictionary =
        @{NSViewAnimationTargetKey: oldView,
	  NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect};

    NSDictionary *fadeInDictionary =
        @{NSViewAnimationTargetKey: newView,
          NSViewAnimationEffectKey: NSViewAnimationFadeInEffect};

    NSDictionary *resizeDictionary =
        @{NSViewAnimationTargetKey: [self window],
          NSViewAnimationStartFrameKey: [NSValue valueWithRect:[[self window] frame]],
          NSViewAnimationEndFrameKey: [NSValue valueWithRect:[self frameForView:newView]]};
	
    NSArray *animationArray = @[fadeOutDictionary, fadeInDictionary, resizeDictionary];
	
    [viewAnimation setViewAnimations:animationArray];
    [viewAnimation startAnimation];
}

- (void)animationDidEnd:(NSAnimation *)animation
{
    NSView *subview;
	
    // Get a list of all of the views in the window. Hopefully
    // at this point there are two. One is visible and one is hidden.
    NSEnumerator *subviewsEnum = [[contentSubview subviews] reverseObjectEnumerator];
	
    // This is our visible view. Just get past it.
    subview = [subviewsEnum nextObject];
    (void) subview;

    // Remove everything else. There should be just one, but
    // if the user does a lot of fast clicking, we might have
    // more than one to remove.
    while ((subview = [subviewsEnum nextObject]) != nil) {
        [subview removeFromSuperviewWithoutNeedingDisplay];
    }

    // This is a work-around that prevents the first
    // toolbar icon from becoming highlighted.
    [[self window] makeFirstResponder:nil];
}

// Calculate the window size for the new view.
- (NSRect)frameForView:(NSView *)view
{
    NSRect windowFrame = [[self window] frame];
    NSRect contentRect = [[self window] contentRectForFrameRect:windowFrame];
    CGFloat windowTitleAndToolbarHeight = NSHeight(windowFrame) - NSHeight(contentRect);

    windowFrame.size.height = NSHeight([view frame]) + windowTitleAndToolbarHeight;
    windowFrame.size.width = NSWidth([view frame]);
    windowFrame.origin.y = NSMaxY([[self window] frame]) - NSHeight(windowFrame);
	
    return windowFrame;
}

@end
