/*
 * pngpaste
 */

#import "pngpaste.h"

void
usage ()
{
    fprintf(stderr,
        "Usage: %s [OPTIONS] <dest.png>\n"
        "\t-\t" "Print to standard output" "\n"
        "\t-b\t" "Print to standard output as base64" "\n"
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
    ImageType imageType = ImageTypeNone;
    if (image != nil) {
        NSArray *reps = [image representations];
        NSImageRep *rep = [reps lastObject];
        if ([rep isKindOfClass:[NSPDFImageRep class]]) {
            imageType = ImageTypePDF;
        } else if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            imageType = ImageTypeBitmap;
        }
    }
    return imageType;
}

NSData *
renderImageData (NSImage *image, NSBitmapImageFileType bitmapImageFileType)
{
    ImageType imageType = extractImageType(image);
    switch (imageType) {
    case ImageTypeBitmap:
        return renderFromBitmap(image, bitmapImageFileType);
        break;
    case ImageTypePDF:
        return renderFromPDF(image, bitmapImageFileType);
        break;
    case ImageTypeNone:
    default:
        return nil;
        break;
    }
}

NSData *
renderFromBitmap (NSImage *image, NSBitmapImageFileType bitmapImageFileType)
{
    return [NSBitmapImageRep representationOfImageRepsInArray:[image representations]
                                                    usingType:bitmapImageFileType
                                                   properties:@{}];
}

NSData *
renderFromPDF (NSImage *image, NSBitmapImageFileType bitmapImageFileType)
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
                       representationUsingType:bitmapImageFileType
                                    properties:@{}];
}

/*
 * Returns NSBitmapImageFileType based off of filename extension
 */
NSBitmapImageFileType
getBitmapImageFileTypeFromFilename (NSString *filename)
{
    static NSDictionary *lookup;
    if (lookup == nil) {
        lookup = @{
            @"gif": [NSNumber numberWithInt:NSBitmapImageFileTypeGIF],
            @"jpeg": [NSNumber numberWithInt:NSBitmapImageFileTypeJPEG],
            @"jpg": [NSNumber numberWithInt:NSBitmapImageFileTypeJPEG],
            @"png": [NSNumber numberWithInt:NSBitmapImageFileTypePNG],
            @"tif": [NSNumber numberWithInt:NSBitmapImageFileTypeTIFF],
            @"tiff": [NSNumber numberWithInt:NSBitmapImageFileTypeTIFF],
        };
    }
    NSBitmapImageFileType bitmapImageFileType = NSBitmapImageFileTypePNG;
    if (filename != nil) {
        NSArray *words = [filename componentsSeparatedByString:@"."];
        NSUInteger len = [words count];
        if (len > 1) {
            NSString *extension = (NSString *)[words objectAtIndex:(len - 1)];
            NSString *lowercaseExtension = [extension lowercaseString];
            NSNumber *value = lookup[lowercaseExtension];
            if (value != nil) {
                bitmapImageFileType = [value unsignedIntegerValue];
            }
        }
    }
    return bitmapImageFileType;
}

/*
 * Returns NSData from Pasteboard Image if available; otherwise nil
 */
NSData *
getPasteboardImageData (NSBitmapImageFileType bitmapImageFileType)
{
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    NSImage *image = [[NSImage alloc] initWithPasteboard:pasteBoard];
    NSData *imageData = nil;

    if (image != nil) {
        imageData = renderImageData(image, bitmapImageFileType);
    }

    [image release];
    return imageData;
}

Parameters
parseArguments (int argc, char* const argv[])
{
    Parameters params;

    params.outputFile = nil;
    params.wantsVersion = NO;
    params.wantsUsage = NO;
    params.wantsBase64 = NO;
    params.wantsStdout = NO;
    params.malformed = NO;

    int ch;
    while ((ch = getopt(argc, argv, "bvh?")) != -1) {
        switch (ch) {
        case 'b':
            params.wantsBase64 = YES;
            return params;
            break;
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


/*
 * Mapping from 6 bit pattern to ASCII character.
 */
static unsigned char base64EncodeLookup[65] =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*
 * Returns the encoded base64 into a newly malloced buffer. Must be free'd by caller. Length is given by outputLength. 
 */
char *NewBase64Encode(
	const void *buffer,
	size_t length,
	bool separateLines,
	size_t *outputLength)
{
	const unsigned char *inputBuffer = (const unsigned char *)buffer;
	
	//
	// Byte accurate calculation of final buffer size
	//
	size_t outputBufferSize =
			((length / BINARY_UNIT_SIZE)
				+ ((length % BINARY_UNIT_SIZE) ? 1 : 0))
					* BASE64_UNIT_SIZE;
	if (separateLines)
	{
		outputBufferSize +=
			(outputBufferSize / OUTPUT_LINE_LENGTH) * CR_LF_SIZE;
	}
	
	//
	// Include space for a terminating zero
	//
	outputBufferSize += 1;

	//
	// Allocate the output buffer
	//
	char *outputBuffer = (char *)malloc(outputBufferSize);
	if (!outputBuffer)
	{
		return NULL;
	}

	size_t i = 0;
	size_t j = 0;
	const size_t lineLength = separateLines ? INPUT_LINE_LENGTH : length;
	size_t lineEnd = lineLength;
	
	while (true)
	{
		if (lineEnd > length)
		{
			lineEnd = length;
		}

		for (; i + BINARY_UNIT_SIZE - 1 < lineEnd; i += BINARY_UNIT_SIZE)
		{
			//
			// Inner loop: turn 48 bytes into 64 base64 characters
			//
			outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
			outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
				| ((inputBuffer[i + 1] & 0xF0) >> 4)];
			outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)
				| ((inputBuffer[i + 2] & 0xC0) >> 6)];
			outputBuffer[j++] = base64EncodeLookup[inputBuffer[i + 2] & 0x3F];
		}
		
		if (lineEnd == length)
		{
			break;
		}
		
		//
		// Add the newline
		//
		outputBuffer[j++] = '\r';
		outputBuffer[j++] = '\n';
		lineEnd += lineLength;
	}
	
	if (i + 1 < length)
	{
		//
		// Handle the single '=' case
		//
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
			| ((inputBuffer[i + 1] & 0xF0) >> 4)];
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i + 1] & 0x0F) << 2];
		outputBuffer[j++] =	'=';
	}
	else if (i < length)
	{
		//
		// Handle the double '=' case
		//
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
		outputBuffer[j++] = '=';
		outputBuffer[j++] = '=';
	}
	outputBuffer[j] = 0;
	
	//
	// Set the output length and return the buffer
	//
	if (outputLength)
	{
		*outputLength = j;
	}
	return outputBuffer;
}

@implementation NSData (Base64)
- (NSString *)base64EncodedString
{
	size_t outputLength;
	char *outputBuffer =
		NewBase64Encode([self bytes], [self length], false, &outputLength);
	
	NSString *result =
		[[[NSString alloc]
			initWithBytes:outputBuffer
			length:outputLength
			encoding:NSASCIIStringEncoding]
		autorelease];
	free(outputBuffer);
	return result;
}
@end

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

    NSBitmapImageFileType bitmapImageFileType =
        getBitmapImageFileTypeFromFilename(params.outputFile);
    NSData *imageData = getPasteboardImageData(bitmapImageFileType);
    int exitCode;

    if (imageData != nil) {
        if (params.wantsStdout) {
            NSFileHandle *stdout =
                (NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput];
            [stdout writeData:imageData];
            exitCode = EXIT_SUCCESS;
        } else if (params.wantsBase64) {
            NSFileHandle *stdout =
                (NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput];
            NSString *base64String = [imageData base64EncodedString];
            [stdout writeData:[base64String dataUsingEncoding:NSUTF8StringEncoding]];
            exitCode = EXIT_SUCCESS;
        } else {
            if ([imageData writeToFile:params.outputFile atomically:YES]) {
                exitCode = EXIT_SUCCESS;
            } else {
                fatal("Could not write to file!");
                exitCode = EXIT_FAILURE;
            }
        }
    } else {
        fatal("No image data found on the clipboard, or could not convert!");
        exitCode = EXIT_FAILURE;
    }

    return exitCode;
}
