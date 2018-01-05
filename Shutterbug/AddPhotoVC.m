//
//  AddPhotoVC.m
//  Shutterbug
//
//  Created by Mircea Dragota on 1/4/18.
//  Copyright © 2018 Dragota Mircea. All rights reserved.
//

#import "AddPhotoVC.h"
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>   // kUTTypeImage

@interface AddPhotoVC () <UITextFieldDelegate,CLLocationManagerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *subtitleTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic,strong) UIImage *image;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic,strong) NSString *thumbnailURL;
@property (nonatomic,strong) NSURL *imageURL;
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic) NSInteger locationErrorCode;
@end

@implementation AddPhotoVC

- (void) viewDidLoad {
    [super viewDidLoad];
    self.image = [UIImage imageNamed:@"no_image.jpg"];
}

+ (BOOL)canAddPhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage ]) {
            if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted) {
                return YES;
            }
        }
    }
    return NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[self class] canAddPhoto]) {
        [self fatalAlert:@"Sorry, this device cannot add a photo."];
    } else { // should check that location services are enabled first
        [self.locationManager startUpdatingLocation];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (CLLocationManager *) locationManager {
    if(!_locationManager) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;

        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager = locationManager;
        [locationManager requestWhenInUseAuthorization];
        [locationManager startMonitoringSignificantLocationChanges];
    }
    return _locationManager;
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    self.location = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.locationErrorCode = error.code;
}


- (void) setImage:(UIImage *)image {
    self.imageView.image = image;
    [[NSFileManager defaultManager] removeItemAtURL:_imageURL error:NULL];
    self.imageURL = nil;
}

- (UIImage *) image {
    return self.imageView.image;
}

- (IBAction)cancel{
    self.image = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}
- (NSURL *) uniqueDocumentURL {
    NSArray *documentDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *unique = [NSString stringWithFormat:@"%.0f",floor([NSDate timeIntervalSinceReferenceDate])];
    return [[documentDirectories firstObject] URLByAppendingPathComponent:unique];
}


-(NSURL *) imageURL {
    if(!_imageURL && self.image) {
        NSURL *url = [self uniqueDocumentURL];
        if(url) {
            NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0);
            if([imageData writeToURL:url atomically:YES]) {
                _imageURL = url;
            }
        }
    }
    return _imageURL;
}

#define UNWIND_SEGUE_IDENTIFIER @"doAddPhoto"

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        Photo *photo = [[Photo alloc]  init];
        
        photo.title = self.titleTextField.text;
        photo.details = self.subtitleTextField.text;
        photo.latitude = self.location.coordinate.latitude;
        photo.longitude = self.location.coordinate.longitude;
        photo.imageURL = self.imageURL;
        photo.thumbnailURL = @"image_taken";
        
        self.addedPhoto = photo;
        self.imageURL = nil;
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        if (!self.image) {
            [self alert:@"No photo taken!"];
            return NO;
        } else if (![self.titleTextField.text length]) {
            [self alert:@"Title required!"];
            return NO;
        } else if (!self.location) {
            switch (self.locationErrorCode) {
                case kCLErrorLocationUnknown:
                    [self alert:@"Couldn't figure out where this photo was taken (yet)."]; break;
                case kCLErrorDenied:
                    [self alert:@"Location Services disabled under Privacy in Settings application."]; break;
                case kCLErrorNetwork:
                    [self alert:@"Can't figure out where this photo is being taken.  Verify your connection to the network."]; break;
                default:
                    [self alert:@"Cant figure out where this photo is being taken, sorry."]; break;
            }
            return NO;
        } else { // should check imageURL too to be sure we could write the file
            return YES;
        }
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

- (void) alert:(NSString *)msg {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Add Photo"
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert
                                 ];
    
    UIAlertAction *okButt = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:okButt];
    [self presentViewController:alert animated:YES completion:nil];
  
}

- (void) fatalAlert:(NSString *)msg {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Add Photo"
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert
                                 ];
    
   
    UIAlertAction *okButt = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:
                             ^(UIAlertAction *action) {
                                 [self cancel];
                             }
                             ];
    
    [alert addAction:okButt];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)takePhoto:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.allowsEditing = YES;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if(!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    self.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
