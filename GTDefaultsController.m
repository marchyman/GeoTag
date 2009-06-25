//
//  GTDefaultsController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/18/09.
//

#import "GTDefaultsController.h"
#import "PathToStringTransformer.h"

NSString * const SSExiftoolPathKey = @"exiftoolPath";
NSString * const SSMakeBackupFilesKey = @"makeBackupFiles";

@implementation GTDefaultsController

#pragma mark -
#pragma mark Class methods

/*
 * Application preference handling initialization
 */
+ (void) initialize
{
    NSValueTransformer *transformer = [[PathToStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer: transformer
				    forName: @"PathToStringTransformer"];

    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setObject: [NSNumber numberWithBool: YES]
		      forKey: SSMakeBackupFilesKey];
    [defaultValues setObject: @"/usr/bin/exiftool"
		      forKey: SSExiftoolPathKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    NSLog(@"Registered defaults %@", defaultValues);
}

+ (NSString *) exiftoolPath
{
    return [[NSUserDefaults standardUserDefaults]
	    stringForKey: SSExiftoolPathKey];

}

+ (BOOL) makeBackupFiles
{
    return [[NSUserDefaults standardUserDefaults]
	    boolForKey: SSMakeBackupFilesKey];
}

#pragma mark -
#pragma mark Preferences toolbar initialization

- (void) setupToolbar
{
    [self addView:generalPreferenceView label:@"General"];

    [self setCrossFade: YES];
    [self setShiftSlowsAnimation: NO];
}

#pragma mark -
#pragma mark actions and delegate functions

- (IBAction) checkExiftoolValidity: (id) sender
{
    NSLog(@"checkExiftoolValidity:");
    (void) sender;
}

- (IBAction) resetExiftoolPath: (id) sender
{
    NSLog(@"resetExiftoolPath:");
    [[NSUserDefaults standardUserDefaults]
     removeObjectForKey:SSExiftoolPathKey];
    (void) sender;
}

- (void)    pathCell: (NSPathCell *) pathCell
willDisplayOpenPanel: (NSOpenPanel *) openPanel
{
    NSLog(@"pathCell:willDisplayOpenPanel:");
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    
    (void) pathCell;
}

@end
