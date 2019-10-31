//
//  SITFakeLocationManager.h
//  SitumSDK
//
//  Created by Cristina Sánchez Barreiro on 24/04/2018.
//  Copyright © 2018 Situm. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 SITLocationManager
 The SITLocationManager class is the central point for configuring the delivery of location- and heading
 related events to your app. You use the shared instance of this class to establish the parameters that determine when
 location and heading events should be delivered and to start and stop the actual delivery of those events.
 
 Set delegate to listen for location updates.
 */
@interface SITFakeLocationManager: SITLocationManager

- (void) updateWithLocation:(SITLocation *) location;

@end
