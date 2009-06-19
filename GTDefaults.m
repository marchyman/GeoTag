//
//  GTDefaults.m
//  GeoTag
//
//  Created by Marco S Hyman on 6/18/09.
//

#import "GTDefaults.h"

NSString * const SSExiftoolPathKey = @"ExiftoolPath";
NSString * const SSExiftoolMakeBackupsKey = @"ExiftoolMakeBackups";

@implementation GTDefaults

/*
 * Might be be better to initialze this from a UserDefaults.plist in the
 * bundle.
 */
+ (void) initialize
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setObject: [NSNumber numberWithBool: YES]
		      forKey: SSExiftoolMakeBackupsKey];
    [defaultValues setObject: @"/usr/bin/exiftool"
		      forKey: SSExiftoolPathKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    NSLog(@"Registered defaults %@", defaultValues);
}

+ (BOOL) willMakeBackupFiles
{
    return [[NSUserDefaults standardUserDefaults]
	    boolForKey: SSExiftoolMakeBackupsKey];
}
@end
