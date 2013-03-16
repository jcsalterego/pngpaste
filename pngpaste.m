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
		id rep = [reps lastObject];
		if (![rep isKindOfClass:[NSImageRep class]]) {
			fprintf(stderr, "No image or pdf data found on the clipboard!!\n");
			return EXIT_FAILURE;
		}
		NSString *filename =
            [[NSString alloc] initWithCString:argv[1]
                                     encoding:NSUTF8StringEncoding];
		NSData *pngData;
		NSImageRep *imageRep = (NSImageRep *)rep;
		if ([rep isKindOfClass:[NSPDFImageRep class]]) {
			NSPDFImageRep *pdfImageRep = (NSPDFImageRep *)imageRep;
			CGFloat factor = 1.5;
			NSRect bounds = NSMakeRect(0, 0,
									   pdfImageRep.bounds.size.width * factor,
									   pdfImageRep.bounds.size.height * factor);
			NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
			[image lockFocus];
			[[NSColor whiteColor] set];
			NSRectFill(bounds);
			[imageRep drawInRect:bounds];
			[image unlockFocus];

			NSData *imageData = [image TIFFRepresentation];
			
			// NSDictionary *pngProp = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0]
			// 													forKey:NSImageCompressionFactor];
			pngData = [[NSBitmapImageRep imageRepWithData:imageData]
						  representationUsingType:NSPNGFileType
									   properties:nil];
		} else {
			pngData = [NSBitmapImageRep
								  representationOfImageRepsInArray:reps
														 usingType:NSPNGFileType
														properties:nil];
		}
        [pngData writeToFile:filename atomically:YES];
    } else {
        fprintf(stderr, "No image data found on the clipboard!\n");
    }

    [image release];
    [pasteBoard release];
    [pool release];

    return EXIT_SUCCESS;
}
