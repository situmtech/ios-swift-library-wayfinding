//
// Created by Lapisoft on 26/1/22.
//

import Foundation

/**
 Errors WayfindinLibrary could raise
 */
public enum WayfindingError: LocalizedError {
    /**
     Select a POI on selectPoi() inside SitumMapsLibrary could return and invalid POI error
     when this poi do no belong to the current building
     */
    case invalidPOI
    /**
     Generic error that represent an unexpected error
     */
    case unknown
    
    /**
     Making a request for a building id might not return anything
     */
    case buildingNotExist
    
    /**
     When making a request it can return an error
     */
    case requestError

    /**
     Error that represents a failure when user request to download tiles offline for building loaded with library
     but they could not be retrieved
     */
    case offlineTilesNotDownloaded
}

extension WayfindingError {
    /**
     Description of error
     */
    public var errorDescription: String? {
        switch self {
        case .invalidPOI:
            return NSLocalizedString("wayfindingError.invalidPoi", bundle: SitumMapsLibrary.bundle, comment: "")
        case .unknown:
            return NSLocalizedString("wayfindingError.unknown", bundle: SitumMapsLibrary.bundle, comment: "")
        case .buildingNotExist:
            return NSLocalizedString("wayfindingError.buildingNotExist", bundle: SitumMapsLibrary.bundle, comment: "")
        case .requestError:
            return NSLocalizedString("wayfindingError.requestError", bundle: SitumMapsLibrary.bundle, comment: "")
        case .offlineTilesNotDownloaded:
            return NSLocalizedString("wayfindingError.offlineTilesNotDownloaded", bundle: SitumMapsLibrary.bundle, comment: "")
        }
    }
    /**
     Code of error
     */
    public var _code: Int {
        switch self {
        case .invalidPOI:
            return 10_001
        case .unknown:
            return 10_002
        case .buildingNotExist:
            return 10_003
        case .requestError:
            return 10_004
        case .offlineTilesNotDownloaded:
            return 10_005
        }
    }
}
