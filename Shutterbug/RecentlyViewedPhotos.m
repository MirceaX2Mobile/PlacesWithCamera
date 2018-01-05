//
//  RecentlyViewedPhotos.m
//  Shutterbug
//
//  Created by Dragota Mircea on 18/12/2017.
//  Copyright © 2017 Dragota Mircea. All rights reserved.
//

#import "RecentlyViewedPhotos.h"
#import "FlickrFetcher.h"
#import "ImagesTableViewController.h"
#import "Photo.h"
#import "PhotosMapViewController.h"

@interface RecentlyViewedPhotos ()
@property (nonatomic,strong) NSUserDefaults *defaults;
@end


@implementation RecentlyViewedPhotos

- (NSUserDefaults *)defaults {
    if(!_defaults) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.recentlySelectedPlaces = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"recentlySelectedPlaces"]];
   
    [self.tableView reloadData];
    
}



- (NSMutableArray *)recentlySelectedPlaces {
    if(!_recentlySelectedPlaces) {
        _recentlySelectedPlaces = [[NSMutableArray alloc] init];
    }
    return _recentlySelectedPlaces;
}

- (void)didSelectDictionary:(NSDictionary *)metaData {
    self.recentlySelectedPlaces = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"recentlySelectedPlaces"]];
    if(![self.recentlySelectedPlaces containsObject:metaData]) {
        if([self.recentlySelectedPlaces count] == 20) {
            for(int d = 0; d< [self.recentlySelectedPlaces count] - 1; d++) {
                self.recentlySelectedPlaces[d] = [self.recentlySelectedPlaces objectAtIndex:d+1];
            }
            [self.recentlySelectedPlaces removeObjectAtIndex:[self.recentlySelectedPlaces count] - 1];
        }
        [self.recentlySelectedPlaces addObject: metaData];
        [self.tableView reloadData];
        
        
        [self.defaults setObject:self.recentlySelectedPlaces forKey:@"recentlySelectedPlaces"];
        [self.defaults synchronize];
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.recentlySelectedPlaces count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recentlySelected" forIndexPath:indexPath];
    
    NSDictionary *place = self.recentlySelectedPlaces[indexPath.row];
    
    NSArray *placeComponents = [[place valueForKey:FLICKR_PLACE_NAME] componentsSeparatedByString:@","];
    
    NSString *details = [[NSString alloc] initWithFormat:@"%@, %@",placeComponents[0],placeComponents[1]];
    
    cell.textLabel.text = [placeComponents lastObject];
    cell.detailTextLabel.text = details;
    return cell;
}

- (void)prepareImageViewController:(PhotosMapViewController *)ivc toDisplayPhoto:(id)id_place
{
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
        });
    });
    
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        // find out which row in which section we're seguing from
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
         NSDictionary *place = self.recentlySelectedPlaces[indexPath.row];
        
        if (indexPath) {
            // found it ... are we doing the Display Photo segue?
            if ([segue.identifier isEqualToString:@"DisplayPhotoRecently"]) {
                // yes ... is the destination an ImageViewController?
                if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
                    
               //     ImagesTableViewController *imvc = (ImagesTableViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
                      PhotosMapViewController *imvc =(PhotosMapViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
                    // yes ... then we know how to prepare for that segue!
                    [self prepareImageViewController:imvc
                                      toDisplayPhoto:[place valueForKey:FLICKR_PLACE_ID]];
                }
            }
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
