//
//  RecentlyViewedPhotos.h
//  Shutterbug
//
//  Created by Dragota Mircea on 18/12/2017.
//  Copyright © 2017 Dragota Mircea. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlickrPhotosTVC.h"
#import "JustPostedFlickrPhotosTVC.h"

@interface RecentlyViewedPhotos : UITableViewController <RecentlyViewedPhotoDelegate>
@property (nonatomic,strong) NSMutableArray *recentlySelectedPlaces;
@end
