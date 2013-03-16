/*
 * pngpaste
 */

typedef enum imageTypes
{
    ImageTypeNone = 0,
    ImageTypePNG,
    ImageTypePDF
} ImageType;

#define PDF_SCALE_FACTOR 1.5

void usage (const char **argv);
void fatal (const char *msg);

NSString *extractFilenameFromArgs (const char **argv);
ImageType extractImageType (NSImage *image);
NSData *extractPngData (NSImage *image);
NSData *extractPngDataFromPng (NSImage *image);
NSData *extractPngDataFromPdf (NSImage *image);

int main (int argc, const char **argv);
