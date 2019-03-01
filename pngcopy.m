/*
 * pngcopy
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <unistd.h>

#define APP_NAME "pngcopy"
#define APP_VERSION "0.1.0"
#define STDIN_FILENAME "-"

typedef struct parameters
{
    NSString *imageFile;
    BOOL wantsVersion;
    BOOL wantsUsage;
    BOOL wantsStdin;
    BOOL malformed;
} Parameters;

void
usage ()
{
    fprintf(stderr,
        "Usage: %s [OPTIONS] <source.png>\n"
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

Parameters
parseArguments (int argc, char* const argv[])
{
    Parameters params;

    params.imageFile = nil;
    params.wantsVersion = NO;
    params.wantsUsage = NO;
    params.wantsStdin = NO;
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
    } else if (!strcmp(argv[1], STDIN_FILENAME)) {
        params.wantsStdin = YES;
    } else {
        params.imageFile =
            [[NSString alloc] initWithCString:argv[1]
                                     encoding:NSUTF8StringEncoding];
    }
    return params;
}

int copyToPasteboard(NSData* imageData)
{
	if (imageData == nil) {
		fatal("Could not read data from file!");
		return EXIT_FAILURE;
	}

	NSImage* image = [[NSImage alloc] initWithData:imageData];
	if (image == nil) {
		fatal("Could not read image from file!");
		return EXIT_FAILURE;
	}

    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard clearContents];
	NSArray *copiedObjects = [NSArray arrayWithObject:image];
    [pasteBoard writeObjects:copiedObjects];

	return EXIT_SUCCESS;
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

    NSData *imageData;
    if (params.wantsStdin) {
        NSFileHandle *stdin = [NSFileHandle fileHandleWithStandardInput];
        imageData = [stdin readDataToEndOfFile];
    }
    else {
        imageData = [NSData dataWithContentsOfFile:params.imageFile];
    }

    int exitCode = copyToPasteboard(imageData);
    return exitCode;
}
