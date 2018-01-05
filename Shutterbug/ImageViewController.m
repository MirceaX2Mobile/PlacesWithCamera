//
//  ImageViewController.m
//  Imaginarium
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () <UIScrollViewDelegate, UISplitViewControllerDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation ImageViewController

#pragma mark - View Controller Lifecycle

// add the UIImageView to the MVC's View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

#pragma mark - Properties

// lazy instantiation

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        [_imageView sizeToFit];
        [_imageView setClipsToBounds:YES];
        
    }
    return _imageView;
}

// image property does not use an _image instance variable
// instead it just reports/sets the image in the imageView property
// thus we don't need @synthesize even though we implement both setter and getter


- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image; // does not change the frame of the UIImageView

    // had to add these two lines in Shutterbug to fix a bug in "reusing" ImageViewController's MVC
    self.scrollView.zoomScale = 0.0;
    self.imageView.frame = CGRectMake(0,0, image.size.width, image.size.height);
    
    // self.scrollView could be nil on the next line if outlet-setting has not happened yet
    self.scrollView.contentSize = self.image ? self.image.size  : CGSizeZero;
    

    [self.spinner stopAnimating];
    [self.scrollView addSubview:self.imageView];
    [self setZoomToFitScreen];
}

- (void)setZoomToFitScreen {
    CGFloat widthRatio = self.scrollView.bounds.size.width/self.image.size.width;
    [self.scrollView setMinimumZoomScale:widthRatio];
    [self.scrollView setZoomScale:widthRatio];
}

- (void)centerSubViews {
    CGSize scrollSize = self.scrollView.bounds.size;
    CGRect imageFrame = self.imageView.frame;

    if(imageFrame.size.width < scrollSize.width ) {
        imageFrame.origin.x = (scrollSize.width - imageFrame.size.width) / 2;
    }else {
        imageFrame.origin.x = 0;
    }

    if(imageFrame.size.height < scrollSize.height ) {
        imageFrame.origin.y = (scrollSize.height - self.navigationController.navigationBar.frame.size.height - imageFrame.size.height) / 2;
    }else {
        imageFrame.origin.y = 0;
    }
    self.imageView.frame = imageFrame;
}



- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    
    // next three lines are necessary for zooming
    _scrollView.maximumZoomScale = 4.0;
    _scrollView.delegate = self;

    // next line is necessary in case self.image gets set before self.scrollView does
    // for example, prepareForSegue:sender: is called before outlet-setting phase
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

#pragma mark - UIScrollViewDelegate

// mandatory zooming method in UIScrollViewDelegate protocol

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerSubViews];
}

#pragma mark - Setting the Image from the Image's URL

- (void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
    [self startDownloadingImage];
}

- (void)startDownloadingImage
{
//    self.image = nil;

    if (self.imageURL)
    {
        [self.spinner startAnimating];

        NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        // create the session without specifying a queue to run completion handler on (thus, not main queue)
        // we also don't specify a delegate (since completion handler is all we need)
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
            completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                // this handler is not executing on the main queue, so we can't do UI directly here
                if (!error) {
                    if ([request.URL isEqual:self.imageURL]) {
                        // UIImage is an exception to the "can't do UI here"
                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                        // but calling "self.image =" is definitely not an exception to that!
                        // so we must dispatch this back to the main queue
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.image = image;
                        });
                    }
                }
        }];
        [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    }
}

#pragma mark - UISplitViewControllerDelegate

// this section added during Shutterbug demo

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = aViewController.title;
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}

@end
