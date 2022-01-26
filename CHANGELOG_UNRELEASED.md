## [0.1.20] - 2022-01-26

### Addded
* Added protocol OnMapReadyListener that notifies when it is safe to perform operations over the map. A class that
implement this protocol could be set on SitumMapsLibrary to react to this notification
* Added method on SitumMapLibrary to select a POI on the map. A callback could be passed as a parameter to know when the 
POI was selected (since the action is asynchronous)

