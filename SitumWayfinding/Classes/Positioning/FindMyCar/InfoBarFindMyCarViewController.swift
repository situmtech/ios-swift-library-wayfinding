import Foundation
import UIKit
import GoogleMaps

class InfoBarFindMyCarViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //acceptButton.isEnabled = false
    }

    func setCarPositionMarker(latitude: Double, longitude: Double) {
        
    }
    
    @IBAction func findMyCarAcceptButtonTapped(_ sender: UIButton) {
        if let parent = self.parent as? PositioningViewController {
            parent.showPositioningUI()
            
            
            // parent.renderer.displayLongPressMarker(customMarker, forFloor: floor)
            let markerPosition = parent.mapView.projection.coordinate(for: CGPoint(x: parent.mapView.center.x, y: parent.mapView.center.y))
            if let floor = parent.orderedFloors(buildingInfo: parent.buildingInfo)?[parent.selectedLevelIndex] {
                if let buildingInfo = parent.buildingInfo {
                    parent.addCustomMarker(position: SITPoint(
                        building: buildingInfo.building,
                        floorIdentifier: floor.identifier,
                        coordinate: markerPosition
                    ))
                }
            }
        } else {
            Logger.logErrorMessage("Find my car 'accept' button notify parent of type 'PositioningViewController' but the parent controller is not 'PositioningViewController'")
        }
    }

    @IBAction func findMyCarDeleteButtonTapped(_ sender: Any) {
        if let parent = self.parent as? PositioningViewController {
            parent.removeCustomMarker()
            parent.showPositioningUI()
        } else {
            Logger.logErrorMessage("Find my car 'delete' button notify parent of type 'PositioningViewController' but the parent controller is not 'PositioningViewController'")
        }
    }
    
    
    @IBAction func findMyCarCancelButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Notice", message: "Your changes have not been saved. Do you want to exit?", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Do not save changes", style: UIAlertAction.Style.default, handler: { action in
                    if let parent = self.parent as? PositioningViewController {
                        parent.showPositioningUI()
                    } else {
                        Logger.logErrorMessage("Find my car 'cancel' button notify parent of type 'PositioningViewController' but the parent controller is not 'PositioningViewController'")
                    }

        }))
        alert.addAction(UIAlertAction(title: "Keep editing", style: UIAlertAction.Style.cancel, handler: nil))
        
        if let parent = self.parent as? PositioningViewController {
            
            if (parent.customMarkerPosition != nil) {
                alert.addAction(UIAlertAction(title: "Remove my stored position", style: UIAlertAction.Style.destructive, handler: { action in
                    
                    parent.removeCustomMarker()
                    parent.showPositioningUI()
                    
                }))
            }
            
        } else {
            Logger.logErrorMessage("Find my car 'cancel' button notify parent of type 'PositioningViewController' but the parent controller is not 'PositioningViewController'")
        }
        

        self.present(alert, animated: true, completion: nil)

    }
}
