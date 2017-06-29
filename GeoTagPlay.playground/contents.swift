// Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

/*
// set up source ref I THINK THE PROBLEM IS HERE - NOT GRABBING THE INITIAL DATA
CGImageSourceRef source = CGImageSourceCreateWithURL( (CFURLRef) URL,NULL);

// snag metadata
NSDictionary *metadata = (NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);

// make metadata mutable
NSMutableDictionary *metadataAsMutable = [[metadata mutableCopy] autorelease];

// grab exif
NSMutableDictionary *EXIFDictionary = [[[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy] autorelease];

<< edit exif >>

// add back edited exif
[metadataAsMutable setObject:EXIFDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];

// get source type
CFStringRef UTI = CGImageSourceGetType(source);

// set up write data
NSMutableData *data = [NSMutableData data];
CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data,UTI,1,NULL);

//add the image plus modified metadata PROBLEM HERE? NOT ADDING THE ICON
CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) metadataAsMutable);

// write to data
BOOL success = NO;
success = CGImageDestinationFinalize(destination);

// save data to disk 
[data writeToURL:saveURL atomically:YES];

//cleanup
CFRelease(destination);
CFRelease(source);
*/