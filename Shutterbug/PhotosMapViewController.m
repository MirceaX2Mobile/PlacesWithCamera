//
//  PhotosMapViewController.m
//  Shutterbug
//
//  Created by Dragota Mircea on 20/12/2017.
//  Copyright © 2017 Dragota Mircea. All rights reserved.
//

#import "PhotosMapViewController.h"
#import <MapKit/MapKit.h>
#import "Photo.h"
#import "ImageViewController.h"
#import "FlickrFetcher.h"
#import "AddPhotoVC.h"

@interface PhotosMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

@end

@implementation PhotosMapViewController

- (void)setMapView:(MKMapView *)mapView {
    _mapView = mapView;
    self.mapView.delegate = self; 
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *reuseId = @"PhotosMapViewController";
    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if(!view) {
        view =[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        view.canShowCallout = YES;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
        view.leftCalloutAccessoryView = imageView;
        
        UIButton *disclosureButton = [[UIButton alloc] init];
        [disclosureButton setBackgroundImage:[UIImage imageNamed:@"disclosure"] forState:UIControlStateNormal];
        [disclosureButton sizeToFit];
        view.rightCalloutAccessoryView = disclosureButton;
        
    }
    view.annotation = annotation;
    
  
    return view;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
      [self updateLeftCalloutAccessoryViewInAnnotationView:view];
}


- (void)updateLeftCalloutAccessoryViewInAnnotationView:(MKAnnotationView *)annotationView
{
    UIImageView *imageView = nil;
    if ([annotationView.leftCalloutAccessoryView isKindOfClass:[UIImageView class]]) {
        imageView = (UIImageView *)annotationView.leftCalloutAccessoryView;
    }
    if (imageView) {
        Photo *photo = nil;
        if ([annotationView.annotation isKindOfClass:[Photo class]]) {
            photo = (Photo *)annotationView.annotation;
        }
        if (photo) {
#warning Blocking main queue!
            if(![photo.thumbnailURL isEqualToString:@"image_taken"] ) {
            imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]]];
            }else {
                  imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL: photo.imageURL]];
            }
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"showPhotoFromMap" sender:view];
}

- (void)prepareImageViewController:(ImageViewController *)ivc toDisplayPhoto:(NSDictionary *)photo
{
    ivc.imageURL = [FlickrFetcher URLforPhoto:photo format:FlickrPhotoFormatLarge];
    ivc.title = [photo valueForKeyPath:FLICKR_PHOTO_TITLE];
}

- (void)prepareImageViewController:(ImageViewController *)ivc toDisplayPhotoTaken:(Photo *)photo
{
    ivc.imageURL = photo.imageURL;
    ivc.title = @"Your photo";
}


- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
             toShowAnnotation:(id <MKAnnotation>)annotation
{
    Photo *photo = nil;
    if ([annotation isKindOfClass:[Photo class]]) {
        photo = (Photo *)annotation;
    }
    if (photo) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"showPhotoFromMap"]) {
            if ([vc isKindOfClass:[ImageViewController class]]) {
                ImageViewController *ivc = (ImageViewController *)vc;
                if([photo.thumbnailURL isEqualToString:@"image_taken"]) {
                    [self prepareImageViewController:ivc toDisplayPhotoTaken:photo];
                }else {
                [self prepareImageViewController:ivc
                                  toDisplayPhoto:photo.dictionary];
                }
            }
        }
    }
}

- (IBAction) addedPhoto:(UIStoryboardSegue *)segue {
    if([segue.sourceViewController isKindOfClass:[AddPhotoVC class]]) {
        AddPhotoVC *addVc = (AddPhotoVC *) segue.sourceViewController;
        Photo *addedPhoto = addVc.addedPhoto;
        if(addedPhoto) {
            NSArray *array = [[NSArray alloc] initWithObjects:addedPhoto, nil];
            self.images = array;
        }
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([sender isKindOfClass:[MKAnnotationView class]]) {
        [self prepareViewController:segue.destinationViewController
                           forSegue:segue.identifier
                   toShowAnnotation:((MKAnnotationView *)sender).annotation];
    }
}


- (void)setImages:(NSArray *)images {
    _images = images;
    [self updateMapViewAnnotations];
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    if(self.cameraButton) {
//
//        NSMutableArray *rightButtonsItems = [self.navigationItem.rightBarButtonItems mutableCopy];
//        if(!rightButtonsItems){
//            rightButtonsItems =[[NSMutableArray alloc] init];
//        }
//        NSUInteger addPhotoButton = [rightButtonsItems indexOfObject:self.cameraButton];
//        if(addPhotoButton == NSNotFound) {
//            if(self.myPhotos) {
//                [rightButtonsItems addObject:self.cameraButton];
//            }
//        }else {
//            if(!self.myPhotos) {
//                [rightButtonsItems removeObjectAtIndex:addPhotoButton];
//            }
//        }
//        self.navigationItem.rightBarButtonItems = rightButtonsItems;
//    }
    
    if(self.myPhotos) {
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(presentModal:)];
        
       
        self.navigationItem.rightBarButtonItem = rightItem;
    }
}
-(void)presentModal:(id)sender{
    [self performSegueWithIdentifier:@"modalSegue" sender:sender];
}


- (void)setMyPhotos:(bool)myPhotos {
    
     _myPhotos = myPhotos;
        }


- (void)updateMapViewAnnotations {
    [self.mapView removeAnnotations:self.mapView.annotations]	;
    [self.mapView addAnnotations:self.images];
    [self.mapView showAnnotations:self.images animated:YES];
}




@end
