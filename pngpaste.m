/*
 * pngpaste
 */

#import "pngpaste.h"

void
usage ()
{
    fprintf(stderr,
        "Usage: %s [OPTIONS] <dest.png>\n"
        "\t-v\t" "Version" "\n"
        "\t-h,-?\t" "This usage" "\n",
        APP_NAME);
}

void
fatal (const char *msg)
{
    if (msg != NULL) {
        fprintf(stderr, "%s: %s\n", APP_NAME, msg);
    }
}

void
version ()
{
    fprintf(stderr, "%s %s\n", APP_NAME, APP_VERSION);
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

Parameters
parseArguments (int argc, char* const argv[])
{
    Parameters params;

    params.outputFile = NULL;
    params.wantsVersion = NO;
    params.wantsUsage = NO;
    params.wantsStdout = NO;
    params.malformed = NO;

    int ch;
    while ((ch = getopt(argc, argv, "vh?")) != -1) {
        switch (ch) {
        case 'v':
            params.wantsVersion = YES;
            return params;
            break;
        case 'h':
        case '?':
            params.wantsUsage = YES;
            return params;
            break;
        default:
            params.malformed = YES;
            return params;
            break;
        }
    }

    if (argc < 2) {
        params.malformed = YES;
    } else if (!strcmp(argv[1],STDOUT_FILENAME)) {
        params.wantsStdout = YES;
    } else {
        params.outputFile =
            [[NSString alloc] initWithCString:argv[1]
                                     encoding:NSUTF8StringEncoding];
    }
    return params;
}

int
main (int argc, char * const argv[])
{
    Parameters params = parseArguments(argc, argv);
    if (params.malformed) {
        usage();
        return EXIT_FAILURE;
    } else if (params.wantsUsage) {
        usage();
        return EXIT_SUCCESS;
    } else if (params.wantsVersion) {
        version();
        return EXIT_SUCCESS;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    NSImage *image = [[NSImage alloc] initWithPasteboard:pasteBoard];
    NSData *pngData;
    int exitCode;

    if (image && ((pngData = extractPngData(image)) != NULL)) {
        if (params.wantsStdout) {
            NSFileHandle *stdout =
                (NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput];
            [stdout writeData:pngData];
            exitCode = EXIT_SUCCESS;
        } else {
            if ([pngData writeToFile:params.outputFile atomically:YES]) {
                exitCode = EXIT_SUCCESS;
            } else {
                fatal("Could not write to file!");
                exitCode = EXIT_FAILURE;
            }
        }
    } else {
        fatal("No image data found on the clipboard!");
        exitCode = EXIT_FAILURE;
    }

    [image release];
    [pasteBoard release];
    [pool release];

    return exitCode;
}
