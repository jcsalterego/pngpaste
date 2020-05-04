/*
 * pngpaste
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <unistd.h>

#define APP_NAME "pngpaste"
#define APP_VERSION "0.2.2"
#define PDF_SCALE_FACTOR 1.5
#define STDOUT_FILENAME "-"
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4
#define MAX_NUM_PADDING_CHARS 2
#define OUTPUT_LINE_LENGTH 64
#define INPUT_LINE_LENGTH ((OUTPUT_LINE_LENGTH / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE)
#define CR_LF_SIZE 2

typedef enum imageType
{
    ImageTypeNone = 0,
    ImageTypePDF,
    ImageTypeBitmap,
} ImageType;

typedef struct parameters
{
    NSString *outputFile;
    BOOL wantsVersion;
    BOOL wantsUsage;
    BOOL wantsStdout;
    BOOL wantsBase64;
    BOOL malformed;
} Parameters;

void usage ();
void fatal (const char *msg);
void version ();

ImageType extractImageType (NSImage *image);
NSData *renderImageData (NSImage *image, NSBitmapImageFileType bitmapImageFileType);
NSData *renderFromBitmap (NSImage *image, NSBitmapImageFileType bitmapImageFileType);
NSData *renderFromPDF (NSImage *image, NSBitmapImageFileType bitmapImageFileType);
NSBitmapImageFileType getBitmapImageFileTypeFromFilename (NSString *filename);
NSData *getPasteboardImageData (NSBitmapImageFileType bitmapImageFileType);

Parameters parseArguments (int argc, char* const argv[]);

char *NewBase64Encode(
	const void *inputBuffer,
	size_t length,
	bool separateLines,
	size_t *outputLength);

@interface NSData (Base64)
- (NSString *)base64EncodedString;
@end

int main (int argc, char * const argv[]);
