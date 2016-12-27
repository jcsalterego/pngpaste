/*
 * pngpaste
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <unistd.h>

#define APP_NAME "pngpaste"
#define APP_VERSION "0.2.1"
#define PDF_SCALE_FACTOR 1.5
#define STDOUT_FILENAME "-"

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


int main (int argc, char * const argv[]);
