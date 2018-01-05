//
//  FlickrPhotosTVC.m
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "FlickrPhotosTVC.h"
#import "FlickrFetcher.h"
#import "ImageViewController.h"
#import "RecentlyViewedPhotos.h"
#import "ImagesTableViewController.h"
#import "Photo.h"
#import "PhotosMapViewController.h"


@interface FlickrPhotosTVC()
@property (nonatomic,strong) NSDictionary *countryDict;
@end

@implementation FlickrPhotosTVC


// whenever our Model is set, must update our View

- (NSDictionary *)countryDict {
    if (self.places == nil || self.places.count == 0) {
        return @{};
    }
    if(!_countryDict) {
        NSMutableDictionary *countryDictionary = [NSMutableDictionary new];
        
        for (NSDictionary *place in self.places) {
            NSArray *placeComponents = [[place valueForKey:FLICKR_PLACE_NAME] componentsSeparatedByString:@","];
            if (placeComponents == nil || [placeComponents count] == 0) {
                continue;
            }
            NSString *country = [placeComponents  lastObject];
            NSMutableArray *arrayMeta = [countryDictionary objectForKey:country];
            if (arrayMeta == nil) {
                arrayMeta = [NSMutableArray new];
            }
            [arrayMeta addObject:place];
            [countryDictionary setObject:arrayMeta forKey:country];
            
        }
        
        _countryDict = countryDictionary;
    }
    
    return _countryDict;
}



- (void)setPlaces:(NSArray *)places
{
    _places = places;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

// the methods in this protocol are what provides the View its data
// (remember that Views are not allowed to own their data)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.

    return [self.countryDict count] + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section != 0) {
        return [self.countryDict allKeys][section - 1];
    }else {
        return @"My Photos";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section!=0) {
    // Return the number of rows in the section (we only have one)
    NSArray *keys = [self.countryDict allKeys];
    
    return [(NSArray *)[self.countryDict objectForKey:keys[section - 1]] count];
    }else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we must be sure to use the same identifier here as in the storyboard!
    static NSString *CellIdentifier = @"Flickr Photo Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    // get the photo out of our Model
    if(indexPath.section!=0){
    
    NSArray *keys = [self.countryDict allKeys];
    NSMutableArray *placesArray =  [self.countryDict objectForKey:keys[indexPath.section - 1]];
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:FLICKR_PLACE_NAME
                                                                 ascending:YES];
    NSArray *sortedArray = [placesArray sortedArrayUsingDescriptors:@[sortByName]];
    
    NSDictionary *place = sortedArray[indexPath.row];
   
    // update UILabels in the UITableViewCell
    // valueForKeyPath: supports "dot notation" to look inside dictionaries at other dictionaries
    
    cell.textLabel.text = [place valueForKeyPath:FLICKR_PLACE_NAME];
    cell.detailTextLabel.text = [place valueForKeyPath:FLICKR_PLACE_ID];
    
    return cell;
    } else {
        cell.textLabel.text = @"My Photos";
        return cell;
    }
}

#pragma mark - UITableViewDelegate

// when a row is selected and we are in a UISplitViewController,
//   this updates the Detail ImageViewController (instead of segueing to it)
// knows how to find an ImageViewController inside a UINavigationController in the Detail too
// otherwise, this does nothing (because detail will be nil and not "isKindOfClass:" anything)


#pragma mark - Navigation

// prepares the given ImageViewController to show the given photo
// used either when segueing to an ImageViewController
//   or when our UISplitViewController's Detail view controller is an ImageViewController

- (void)prepareImageViewController:(PhotosMapViewController *)ivc toDisplayPhoto:(id)id_place
{
    if(id_place != 0) {
    NSMutableArray *photos = [[NSMutableArray alloc] init];
   // ivc.imageURL = [FlickrFetcher URLforPhoto:photo format:FlickrPhotoFormatLarge];
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("flickr fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Flickr
        NSData *jsonResults = [NSData dataWithContentsOfURL:[FlickrFetcher URLforPhotosInPlace:id_place maxResults:50]];
        NSArray *places = nil;
        
        if(jsonResults) {
            // convert it to a Property List (NSArray and NSDictionary)
            NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                                options:0
                                                                                  error:NULL];
         places = [propertyListResults valueForKeyPath:FLICKR_RESULTS_PHOTOS];
            
            for(NSDictionary *place in places) {
                Photo *photo = [[Photo alloc] init];
                photo.photoId = [place valueForKeyPath:FLICKR_PHOTO_ID];
                photo.title = [place valueForKeyPath:FLICKR_PHOTO_TITLE];
                photo.details = [place valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
                photo.longitude = [[place valueForKey:FLICKR_LONGITUDE ] doubleValue]; // poate nu merge
                photo.latitude = [[place valueForKey:FLICKR_LATITUDE] doubleValue];
                photo.thumbnailURL = [[FlickrFetcher URLforPhoto:place format:FlickrPhotoFormatSquare] absoluteString];
                photo.dictionary = place;
                [photos addObject:photo];
            }
            
        }
        // get the NSArray of photo NSDictionarys out of the results
        
        // update the Model (and thus our UI), but do so back on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
          //  [self.refreshControl endRefreshing]; // stop the spinner
           ivc.images = photos;
            ivc.myPhotos = false;
        });
    });
    }else {
        ivc.images = nil;
        ivc.myPhotos = true;
    }
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section != 0 ) {
    NSArray *keys = [self.countryDict allKeys];
    NSMutableArray *placesArray =  [self.countryDict objectForKey:keys[indexPath.section - 1]];

    [self.delegate didSelectDictionary:placesArray[indexPath.row]];
    }
    
}



// In a story board-based application, you will often want to do a little preparation before navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
   
    
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        // find out which row in which section we're seguing from
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        if(indexPath.section != 0) {
            NSArray *keys = [self.countryDict allKeys];
            NSMutableArray *placesArray =  [self.countryDict objectForKey:keys[indexPath.section - 1]];
            NSDictionary *place = placesArray[indexPath.row];
            
            
            if (indexPath) {
                // found it ... are we doing the Display Photo segue?
                if ([segue.identifier isEqualToString:@"Display Photo"]) {
                    // yes ... is the destination an ImageViewController?
                    if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {

                        PhotosMapViewController *imvc =(PhotosMapViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
                        
                        // yes ... then we know how to prepare for that segue!
                       [self prepareImageViewController:imvc
                                         toDisplayPhoto:[place valueForKey:FLICKR_PLACE_ID]];
                    }
                }
            }
        }else {
            PhotosMapViewController *imvc =(PhotosMapViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
            [self prepareImageViewController:imvc
                              toDisplayPhoto:0];
        }
    }
}

@end

