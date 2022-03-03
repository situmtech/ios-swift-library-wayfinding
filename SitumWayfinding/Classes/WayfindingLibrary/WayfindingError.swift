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
}

extension WayfindingError {
    /**
     Description of error
     */
    public var errorDescription: String? {
        switch self {
        case .invalidPOI:
            return NSLocalizedString("wayfindingError.invalidPoi", comment: "")
        case .unknown:
            return NSLocalizedString("wayfindingError.unknown", comment: "")
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
        }
    }
}
