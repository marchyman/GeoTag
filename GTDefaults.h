//
//  GTDefaults.h
//  GeoTag
//
//  Created by Marco S Hyman on 6/18/09.
//

#import <Cocoa/Cocoa.h>

extern NSString * const SSExiftoolPathKey;
extern NSString * const SSExiftoolMakeBackupsKey;

@interface GTDefaults : NSObject {

}

+ (BOOL) willMakeBackupFiles;

@end
