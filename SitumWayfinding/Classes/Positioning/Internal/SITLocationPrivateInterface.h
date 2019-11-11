//
//  SITLocationPrivateInterface.h
//  SitumSDK
//
//  Created by Adrián Rodríguez on 14/01/2019.
//  Copyright © 2019 Situm. All rights reserved.
//

@protocol SITLocationPrivateDelegate <SITLocationDelegate>

- (void)locationManager:(nonnull id <SITLocationInterface>)locationManager
      didUpdateRangedBeacons: (NSInteger) numberOfRangedBeacons;

@end

