//
//  PhotosMapViewController.h
//  Shutterbug
//
//  Created by Dragota Mircea on 20/12/2017.
//  Copyright © 2017 Dragota Mircea. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotosMapViewController : UIViewController
@property (nonatomic,strong) NSArray *images;
@property (nonatomic) bool myPhotos;
- (void)setMyPhotos:(bool)myPhotos;
@end
