//
// Created by Lapisoft MacPro on 18/10/22.
//

import Foundation
import SitumSDK

class BuildingManager {
    private(set) var buildingInfo: SITBuildingInfo
    private var pois: [SITPOI] = []
    private var categoriesToFilter: [SITPOICategory] = []
    // we use a hash table because in this case we use weak objects to avoid retention cycles
    private var delegates: NSHashTable<BuildingManagerDelegate> = NSHashTable.weakObjects()

    init?(buildingInfo: SITBuildingInfo) {
        guard buildingInfo.floors.count > 0 else { return nil }
        self.buildingInfo = buildingInfo
        pois = buildingInfo.indoorPois
    }

    //MARK: Handle categories
    func setFilterCategories(_ categories: [SITPOICategory]) {
        categoriesToFilter = categories
        delegates.allObjects.forEach { delegate in delegate.categoriesWhereChanged() }
    }

    //MARK: Filtering pois
    /**
      If categories is an empty array it will return all pois without filtering
     - Returns: filtered pois by categories set in building manager
     */
    func filterPoisByCategories() -> [SITPOI] {
        return pois.filterByCategories(categoriesToFilter)
    }

    //MARK: Handling observers
    func addDelegate(_ delegate: BuildingManagerDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: BuildingManagerDelegate) {
        delegates.remove(delegate)
    }

    //MARK: Utils
    func floorForPoi(_ poi: SITPOI) -> SITFloor? {
        guard let floor = buildingInfo.floors.first(where: { $0.identifier ==  poi.position().floorIdentifier }) else {
            return nil
        }
        return floor
    }
}


@objc protocol BuildingManagerDelegate {
    func categoriesWhereChanged()
}

extension Array where Element == SITPOI {
    func filterByFloor(_ floor: SITFloor) -> [Element] {
        return self.filter { poi in poi.position().floorIdentifier == floor.identifier }
    }

    /**
     Filter by categories
     - Parameter categories: categories to filter
     - Returns: filtered pois by categories. If categories is an empty array will return the array as is without filter
     */
    func filterByCategories(_ categories: [SITPOICategory]) -> [Element] {
        if categories.count > 0 {
            let categoryIds = Set(categories.map { $0.identifier })
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
    func filterByName(_ name: String) -> [Element] {
        if name.isEmpty {
            return self
        } else {
            return self.filter { $0.name.lowercased().contains(name) }
        }
    }
}
