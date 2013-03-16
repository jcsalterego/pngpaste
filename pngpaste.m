/*
 * pngpaste
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "pngpaste.h"

void
usage (const char **argv)
{
    fprintf(stderr, "usage: %s <dest.png>\n", argv[0]);
}

void
fatal (const char *msg)
{
    if (msg != NULL) {
        fprintf(stderr, "%s\n", msg);
    }
}

NSString *
extractFilenameFromArgs (const char **argv)
{
    return [[NSString alloc] initWithCString:argv[1]
                                    encoding:NSUTF8StringEncoding];
}

ImageType
extractImageType (NSImage *image)
{
    if (image != NULL) {
        NSArray *reps = [image representations];
        id rep = [reps lastObject];
        if ([rep isKindOfClass:[NSPDFImageRep class]]) {
            return ImageTypePDF;
        } else if ([rep isKindOfClass:[NSImageRep class]]) {
            return ImageTypePNG;
        }
    }
    return ImageTypeNone;
}

NSData *
extractPngData (NSImage *image)
{
    ImageType imageType = extractImageType(image);
    switch (imageType) {
    case ImageTypePNG:
        return extractPngDataFromPng(image);
        break;
    case ImageTypePDF:
        return extractPngDataFromPdf(image);
        break;
    case ImageTypeNone:
    default:
        return NULL;
        break;
    }
}

NSData *
extractPngDataFromPng (NSImage *image)
{
    return [NSBitmapImageRep
               representationOfImageRepsInArray:[image representations]
                                      usingType:NSPNGFileType
                                     properties:nil];
}

NSData *
extractPngDataFromPdf (NSImage *image)
{
    NSPDFImageRep *pdfImageRep =
        (NSPDFImageRep *)[[image representations] lastObject];
    CGFloat factor = PDF_SCALE_FACTOR;
    NSRect bounds = NSMakeRect(
        0, 0,
        pdfImageRep.bounds.size.width * factor,
        pdfImageRep.bounds.size.height * factor);

    NSImage *genImage = [[NSImage alloc] initWithSize:bounds.size];
    [genImage lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(bounds);
    [pdfImageRep drawInRect:bounds];
    [genImage unlockFocus];

    NSData *genImageData = [genImage TIFFRepresentation];
    return [[NSBitmapImageRep imageRepWithData:genImageData]
                       representationUsingType:NSPNGFileType
                                    properties:nil];
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
    NSData *pngData;

    if (image && ((pngData = extractPngData(image)) != NULL)) {
        NSString *filename = extractFilenameFromArgs(argv);
        [pngData writeToFile:filename atomically:YES];
    } else {
        fatal("No image data found on the clipboard!");
    }

    [image release];
    [pasteBoard release];
    [pool release];

    return EXIT_SUCCESS;
}
