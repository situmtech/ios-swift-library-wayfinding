//
//  SearchTableViewCell.swift
//  SitumWayfinding
//
//  Created by fsvilas on 25/10/21.
//

import Foundation

class SearchTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var floorLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    var name: String {
        get {
            return nameLabel.text ?? ""
        }
        set {
            nameLabel.text = newValue
        }
    }
    var floor: String {
        get {
            return floorLabel.text ?? ""
        }
        set {
            floorLabel.text = newValue
        }
    }

    var distance: String {
        get {
            return distanceLabel.text ?? ""
        }
        set {
            distanceLabel.text = newValue
        }
    }
    var icon: UIImage? {
        get {
            return iconImageView.image
        }
        set {
            iconImageView.image = newValue
        }
    }
}
