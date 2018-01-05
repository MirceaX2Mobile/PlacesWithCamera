//
//  Photo.h
//  Shutterbug
//
//  Created by Dragota Mircea on 18/12/2017.
//  Copyright © 2017 Dragota Mircea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Photo : NSObject
@property (nonatomic,strong) NSString *photoId;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *details;
@property (nonatomic,strong) NSDictionary *dictionary;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic,strong) NSString *thumbnailURL;
@property (nonatomic,strong) NSURL *imageURL;
@end
