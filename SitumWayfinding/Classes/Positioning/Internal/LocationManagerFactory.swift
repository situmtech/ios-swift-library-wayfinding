//
// Created by Lapisoft on 30/3/22.
//

import Foundation
import SitumSDK


class LocationManagerFactory {
    static func createLocationManager() -> SITLocationInterface {
        #if DEBUG
        if (UserDefaultsWrapper.getUseFakeLocations()) {
            return FakeLocationManager()
        } else {
            return SITLocationManager.sharedInstance()
        }
        #else
        return SITLocationManager.sharedInstance()
        #endif
    }
    
    static func addDelegate(object: SITLocationInterface, delegate: SITLocationDelegate) {
        // protocol do not include delegate but we know it exists
        // this could change in the future if delegate is in the protocol definition
        if let manager = object as? SITLocationManager {
            manager.addDelegate(delegate)
        } else if let manager = object as? FakeLocationManager {
            manager.delegate = delegate
        } else {
            Logger.logErrorMessage("Could not cast \(object) to an object with delegate")
        }
    }

    static func removeDelegate(object: SITLocationInterface, delegate: SITLocationDelegate) {
        if let manager = object as? SITLocationManager {
            manager.removeDelegate(delegate)
        } else if let manager = object as? FakeLocationManager {
            manager.delegate = nil
        } else {
            Logger.logErrorMessage("Could not cast \(object) to an object with delegate")
        }
    }
    
    static func update(object: SITLocationInterface, with location: SITLocation) {
        // only update position if it is a fake location manager
        if let manager = object as? FakeLocationManager {
            manager.update(with: location)
        }
    }
    
    static func isFake(object: SITLocationInterface) -> Bool {
        return object.isKind(of: FakeLocationManager.self)
    }
}

fileprivate class FakeLocationManager: NSObject, SITLocationInterface {
    weak var delegate: SITLocationDelegate? = nil
    
    private var location: SITLocation?
    private var timer: Timer?
    private var innerState: SITLocationState = .started
    
    func update(with location: SITLocation) {
        self.location = location
        
        if innerState == .started && timer == nil  {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if let instance = self, let location = instance.location {
                    instance.delegate?.locationManager(instance, didUpdate: location)
                }
            }
        }
    }

    func removeUpdates() {
        removeTimer()
    }
    
    func requestLocationUpdates(_ request: SITLocationRequest?) {}
    
    func state() -> SITLocationState {
        return innerState
    }
    
    func updateLocationParameters(_ update: SITLocationParametersUpdate) {}
    
    deinit {
        removeTimer()
    }
    
    private func removeTimer() {
        innerState = .stopped
        timer?.invalidate()
        timer = nil
    }
}
