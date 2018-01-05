//
//  Photo.m
//  Shutterbug
//
//  Created by Dragota Mircea on 18/12/2017.
//  Copyright © 2017 Dragota Mircea. All rights reserved.
//

#import "Photo.h"
#import <MapKit/MapKit.h>
@interface Photo() <MKAnnotation>

@end


@implementation Photo

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinate;
    
    coordinate.latitude = self.latitude;
    coordinate.longitude = self.longitude;
    
    return coordinate;
}
@end
