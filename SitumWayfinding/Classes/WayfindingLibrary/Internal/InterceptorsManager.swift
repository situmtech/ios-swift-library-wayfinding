//
//  InterceptorsManager.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 18/06/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation
import SitumSDK

class InterceptorsManager {
    
    private var locationRequestInterceptors: [(SITLocationRequest) -> Void]
    private var navigationRequestInterceptors: [(SITNavigationRequest) -> Void]
    private var directionsRequestInterceptors: [(SITDirectionsRequest) -> Void]
    
    init() {
        self.locationRequestInterceptors = []
        self.navigationRequestInterceptors = []
        self.directionsRequestInterceptors = []
    }
    
    func addLocationRequestInterceptor(_ interceptor: @escaping (SITLocationRequest) -> Void) {
        self.locationRequestInterceptors.append(interceptor)
    }
    
    func addDirectionsRequestInterceptor(_ interceptor: @escaping (SITDirectionsRequest) -> Void) {
        self.directionsRequestInterceptors.append(interceptor)
    }
    
    func addNavigationRequestInterceptor(_ interceptor: @escaping (SITNavigationRequest) -> Void) {
        self.navigationRequestInterceptors.append(interceptor)
    }
    
    func onLocationRequest(_ locRequest: SITLocationRequest) -> SITLocationRequest {
        for interceptor in self.locationRequestInterceptors {
            interceptor(locRequest)
        }
        
        return locRequest
    }
    
    func onDirectionsRequest(_ dirRequest: SITDirectionsRequest) -> SITDirectionsRequest {
        for interceptor in self.directionsRequestInterceptors {
            interceptor(dirRequest)
        }
        
        return dirRequest
    }
    
    func onNavigationRequest(_ navRequest: SITNavigationRequest) -> SITNavigationRequest {
        for interceptor in self.navigationRequestInterceptors {
            interceptor(navRequest)
        }
        
        return navRequest
    }
    
}
