/*
 * pngpaste
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

void
usage (const char **argv)
{
    fprintf(stderr, "usage: %s <dest.png>\n", argv[0]);
}

int
main (int argc, const char **argv)
{
    if (argc < 2) {
        usage(argv);
        return EXIT_FAILURE;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    NSImage *image = [[NSImage alloc] initWithPasteboard:pasteBoard];
    if (image) {
        NSArray *reps = [image representations];
        NSData *pngData = [NSBitmapImageRep
                           representationOfImageRepsInArray:reps
                                                  usingType:NSPNGFileType
                                                 properties:nil];
        NSString *filename =
            [[NSString alloc] initWithCString:argv[1]
                                     encoding:NSUTF8StringEncoding];
        [pngData writeToFile:filename atomically:YES];
    } else {
        fprintf(stderr, "No PNG data found on the clipboard!\n");
    }

    [pasteBoard release];
    [pool release];

    return EXIT_SUCCESS;
}
