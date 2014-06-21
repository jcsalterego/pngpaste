/*
 * pngpaste
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <unistd.h>

#define APP_NAME "pngpaste"
#define APP_VERSION "0.2.0"

#define PDF_SCALE_FACTOR 1.5

typedef enum imageTypes
{
    ImageTypeNone = 0,
    ImageTypePNG,
    ImageTypePDF
} ImageType;

typedef struct parameters
{
    NSString *outputFile;
    BOOL wantsVersion;
    BOOL wantsUsage;
    BOOL malformed;
    BOOL forceStandardOutput;
} Parameters;

void usage ();
void fatal (const char *msg);
void version ();

ImageType extractImageType (NSImage *image);
NSData *extractPngData (NSImage *image);
NSData *extractPngDataFromPng (NSImage *image);
NSData *extractPngDataFromPdf (NSImage *image);

Parameters parseArguments (int argc, char* const argv[]);

int main (int argc, char * const argv[]);
