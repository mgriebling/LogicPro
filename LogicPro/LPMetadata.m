//
//  LPMetadata.m
//  LogicPro
//
//  Created by Michael Griebling on 6Dec2013.
//  Copyright (c) 2013 Computer Inspirations. All rights reserved.
//

#import "LPMetadata.h"

@implementation LPMetadata

- (id)initWithThumbnail:(UIImage *)thumbnail {
    if ((self = [super init])) {
//        self.thumbnail = thumbnail;
    }
    return self;
}

- (id)init {
    return [self initWithThumbnail:nil];
}

#pragma mark NSCoding

#define KVersionKey    @"Version"
#define KThumbnailKey  @"Thumbnail"
#define KVersion       1

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:KVersion forKey:KVersionKey];
//    NSData *photoData = UIImagePNGRepresentation(self.thumbnail);
//    [encoder encodeObject:photoData forKey:KThumbnailKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    NSInteger version = [decoder decodeIntForKey:KVersionKey];
    if (version <= KVersion) {
//        NSData *thumbnailData = [decoder decodeObjectForKey:KThumbnailKey];
//        UIImage *thumbnail = [UIImage imageWithData:thumbnailData];
        return [self initWithThumbnail:nil];
    }
    return nil;
}

@end
