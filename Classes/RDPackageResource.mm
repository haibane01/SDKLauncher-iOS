//
//  RDPackageResource.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDPackageResource.h"
#import <ePub3/archive.h>
#import <ePub3/package.h>
#import <ePub3/utilities/byte_stream.h>
#import "RDPackage.h"


@interface RDPackageResource() {
	@private ePub3::ByteStream *m_byteStream;
	@private int m_bytesCount;
}

- (NSData *)createNextChunkByReading;

@end


@implementation RDPackageResource


@synthesize bytesCount = m_bytesCount;
@synthesize byteStream = m_byteStream;
@synthesize relativePath = m_relativePath;


+ (std::size_t)bytesAvailable:(ePub3::ByteStream*)byteStream pack:(RDPackage *)package path:(NSString *)relPath {
    std::size_t size = byteStream->BytesAvailable();
    if (size == 0)
    {
        NSLog(@"BYTESTREAM zero BytesAvailable!");
    }
    else
    {
        return size;
    }

    //std::unique_ptr<ePub3::ArchiveReader> reader = _sdkPackage->ReaderForRelativePath(s);
    //reader->read(<#(void*)p#>, <#(size_t)len#>)

    std::shared_ptr<ePub3::Archive> archive = ((ePub3::Package*)[package sdkPackage])->Archive();

    try
    {
        //ZipItemInfo
        ePub3::ArchiveItemInfo info = archive->InfoAtPath(((ePub3::Package*)[package sdkPackage])->BasePath() + [relPath UTF8String]);
        size = info.UncompressedSize();
    }
    catch (std::exception& e)
    {
        auto msg = e.what();
        NSLog(@"!!! [ArchiveItemInfo] ZIP file not found (corrupted archive?): %@ (%@)", relPath, [NSString stringWithUTF8String:msg]);
    }
    catch (...) {
        throw;
    }

    archive = nullptr;



    std::string s = [relPath UTF8String];
    std::unique_ptr<ePub3::ArchiveReader> reader = ((ePub3::Package*)[package sdkPackage])->ReaderForRelativePath(s);

    if (reader == nullptr)
    {
        NSLog(@"!!! [ArchiveReader] ZIP file not found (corrupted archive?): %@", relPath);
    }
    else
    {
        UInt8 buffer[kSDKLauncherPackageResourceBufferSize];
        std::size_t total = 0;
        std::size_t count = 0;
        while ((count = reader->read(buffer, sizeof(buffer))) > 0)
        {
            total += count;
        }

        if (total > 0)
        {
            // ByteStream bug??! zip_fread works with ArchiveReader, why not ByteStream?
            NSLog(@"WTF??!");

            if (total != size)
            {
                NSLog(@"Oh dear...");
            }
        }
    }

    reader = nullptr;

    return size;
}


- (NSData *)createChunkByReadingRange:(NSRange)range package:(RDPackage *)package {

    if (m_bytesCount == 0)
    {
        return [NSData data];
    }

    if (DEBUGLOG)
    {
        NSLog(@"BYTESTREAM READ %p", m_byteStream);
    }

    if (range.length == 0) {
        return [NSData data];
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream Range %@", m_relativePath);
        NSLog(@"%ld - %ld", (unsigned long)range.location, (unsigned long)range.length);
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream COUNT: %d", m_bytesCount);
    }

    if (NSMaxRange(range) > m_bytesCount) {
        NSLog(@"The requested data range is out of bounds!");
        return nil;
    }

    UInt32 bytesToRead = range.length;

    if (DEBUGLOG)
    {
        NSLog(@"TOTAL %d", m_bytesCount);
        NSLog(@"ByteStream TO READ: %ld", bytesToRead);
    }

    NSMutableData *md = [NSMutableData dataWithCapacity:bytesToRead];

    int bufSize = sizeof(m_buffer);
    std::size_t count = 0;

    //ePub3::SeekableByteStream* seekStream = std::dynamic_pointer_cast<ePub3::SeekableByteStream>(m_byteStream);
    ePub3::SeekableByteStream* seekStream = dynamic_cast<ePub3::SeekableByteStream*>(m_byteStream);

    ePub3::ByteStream::size_type pos = seekStream->Seek(range.location, std::ios::beg);
    if (pos != range.location)
    {
        NSLog(@"Unable to ZIP seek! %ld vs. %ld", pos, (unsigned long)range.location);
        return nil;
    }

    int remainderToRead = bytesToRead;
    int toRead = 0;
    while ((toRead = remainderToRead < bufSize ? remainderToRead : bufSize) > 0 && (count = m_byteStream->ReadBytes(m_buffer, toRead)) > 0)
    {
        [md appendBytes:m_buffer length:count];
        remainderToRead -= count;
    }
    if (remainderToRead != 0)
    {
        NSLog(@"Did not seek-read all ZIP range? %d vs. %ld", remainderToRead, bytesToRead);
        return nil;
    }


    return md;
}

- (NSData *)createNextChunkByReading {

    if (m_bytesCount == 0)
    {
        return [NSData data];
    }

    std::size_t count = m_byteStream->ReadBytes(m_buffer, sizeof(m_buffer));

    return (count == 0) ? nil : [[NSData alloc] initWithBytes:m_buffer length:count];
}


- (void)dealloc {
	[m_delegate rdpackageResourceWillDeallocate:self];
}


- (NSData *)readAllDataChunks {

    if (m_bytesCount == 0)
    {
        return [NSData data];
    }

    NSMutableData *md = [NSMutableData data];

    while (YES) {
        NSData *chunk = [self createNextChunkByReading];

        if (chunk != nil) {
            [md appendData:chunk];
        }
        else {
            break;
        }
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream WHOLE read: %@", m_relativePath);
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream WHOLE: %d (%@)", m_bytesCount, m_relativePath);
    }

    return md;
}


- (id)
	initWithDelegate:(id <RDPackageResourceDelegate>)delegate
	byteStream:(void *)byteStream
	package:(RDPackage *)package
	relativePath:(NSString *)relativePath
{
	if (byteStream == nil || package == nil || relativePath == nil || relativePath.length == 0) {
		return nil;
	}

	if (self = [super init]) {
		m_byteStream = (ePub3::ByteStream *)byteStream;
		m_delegate = delegate;
		m_relativePath = relativePath;
		m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream pack:package path:relativePath];

		if (m_bytesCount == 0) {
			NSLog(@"m_bytesCount == 0 ???? %@", m_relativePath);
		}

        if (DEBUGLOG)
        {
            NSLog(@"INIT ByteStream: %@ (%d)", m_relativePath, m_bytesCount);
            NSLog(@"BYTESTREAM INIT %p", m_byteStream);
        }
	}

	return self;
}


@end
