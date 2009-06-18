//
//  PrefController.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/17/09.
//

#import "PrefController.h"

NSString * const SSExiftoolPathKey = @"ExiftoolPath";

@implementation PrefController


- (id)init
{
    return [super initWithWindowNibName:@"Preferences"];
}

- (NSString *) exiftoolPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey: SSExiftoolPathKey];
}

- (void) windowDidLoad
{
    [exiftoolPath setStringValue: [self exiftoolPath]];
}

- (IBAction) chooseExiftoolPath: (id) sender
{
    (void) sender;
    NSLog(@"Choose button pressed");
    ;;;
}

- (void) setExiftoolPath: (NSTextField*) newExiftoolPath
{
    [exiftoolPath autorelease];
    exiftoolPath = [newExiftoolPath retain];
}

/*
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 return [defaults boolForKey: SSEmptyDocKey];
 
 
 int state = [checkBox state];
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 [defaults setBool: state forKey: SSEmptyDocKey];
 NSLog(@"checkBox changed %d", state);
 
 */

@end
