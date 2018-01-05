//
//  FlickrPhotosTVC.h
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RecentlyViewedPhotoDelegate <NSObject>   //define delegate protocol
- (void) didSelectDictionary: (NSDictionary *)metaData;  //define delegate method to be implemented within another class
@end //end protocol

@interface FlickrPhotosTVC : UITableViewController <UITableViewDelegate, UITableViewDataSource>
// Model of this MVC (it can be publicly set)
@property (nonatomic, strong) NSArray *places; // of Flickr photo NSDictionary
@property (nonatomic, weak) id <RecentlyViewedPhotoDelegate> delegate;
@end

