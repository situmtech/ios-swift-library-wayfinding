//
// Created by Lapisoft MacPro on 18/10/22.
//

import Foundation
import SitumSDK

class BuildingManager {
    private(set) var buildingInfo: SITBuildingInfo
    private var pois: [SITPOI] = []
    private var categoryIdsToFilter: [String] = []
    // we use a hash table (which uses weak references) to avoid retention cycles
    private var delegates: NSHashTable<BuildingManagerDelegate> = NSHashTable.weakObjects()

    init?(buildingInfo: SITBuildingInfo) {
        guard buildingInfo.floors.count > 0 else { return nil }
        self.buildingInfo = buildingInfo
        pois = buildingInfo.indoorPois
    }

    //MARK: Handle categories
    func setPoiFilters(by categoryIds: [String]) {
        categoryIdsToFilter = categoryIds
        delegates.allObjects.forEach { delegate in delegate.poiFiltersByCategoriesWereUpdated() }
    }

    //MARK: Filtering pois
    /**
      If categories is an empty array it will return all pois without filtering
     - Returns: filtered pois by categories set in building manager
     */
    func filterPoisByCategories() -> [SITPOI] {
        return pois.filter(by: categoryIdsToFilter)
    }

    func hasCategoryIdInFilters(_ categoryId: String) -> Bool {
        return categoryIdsToFilter.contains(categoryId)
    }

    //MARK: Handling observers
    func addDelegate(_ delegate: BuildingManagerDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: BuildingManagerDelegate) {
        delegates.remove(delegate)
    }
}


@objc protocol BuildingManagerDelegate {
    func poiFiltersByCategoriesWereUpdated()
}

extension SITPOI {
    func belongs(to floor: SITFloor) -> Bool {
        return position().floorIdentifier == floor.identifier
    }
}

extension Array where Element == SITPOI {
    func filter(by floor: SITFloor) -> [Element] {
        return self.filter { poi in poi.belongs(to: floor) }
    }

    /**
     Filter by categories
     - Parameter categoryIds: category Ids to filter
     - Returns: filtered pois by categories. If categories is an empty array will return the array as is without filter
     */
    func filter(by categoryIds: [String]) -> [Element] {
        if categoryIds.count > 0 {
            return self.filter { categoryIds.contains($0.categoryIdentifier)}
        } else {
            return self
        }
    }

    /**
     Filter by name
     - Parameter name: the name of the poi to search
     - Returns: pois filtered by name. If name is an empty string return the array as is without filtering
     */
    func filter(by name: String) -> [Element] {
        if name.isEmpty {
            return self
        } else {
            return self.filter { $0.name.lowercased().contains(name) }
        }
    }
}
