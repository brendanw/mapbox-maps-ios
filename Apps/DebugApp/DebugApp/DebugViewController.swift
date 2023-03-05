import UIKit
import MapboxMaps

/**
 NOTE: This view controller should be used as a scratchpad
 while you develop new features. Changes to this file
 should not be committed.
 */
final class DebugViewController: UIViewController {

    // views
    var mapView: MapView!

    // Exit annotations
    var isMarkerOpen = false
    var exitName: String = ""
    var exitId: String = ""
    var markerView: UILabel!
    var pointAnnotationManager: PointAnnotationManager!
    var pointAnnotationList: [String: PointAnnotation] = [:]

    // Location
    let locationManager = CLLocationManager()
    var currCoords = CLLocationCoordinate2D(latitude: 38.6403634, longitude: -109.3445153)
    var locationDragged: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    private func setupMapboxMap() {
        /*let styleURI = StyleURI(rawValue: "mapbox://styles/basebeta/cla1us0xn000314mob3xabfm2")!
        let myMapInitOptions = MapInitOptions(
           styleURI: styleURI
        )*/

        mapView = MapView(frame: view.bounds)
        guard let mapView = mapView else {
            return
        }

        /*mapView.mapboxMap.loadStyleURI(styleURI) { [weak self] result in
            self?.mapView!.location.options.activityType = .other
            let configuration = Puck2DConfiguration.makeDefault(showBearing: true)
            self?.mapView!.location.options.puckType = .puck2D(configuration)
            self?.mapView!.location.locationProvider.startUpdatingHeading()
            self?.mapView!.location.locationProvider.startUpdatingLocation()
        }*/

        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMapTapped(_:))))
        mapView.gestures.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.delegate = self

        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }

    @objc private func onMapTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView!)

        if markerView != nil && isMarkerOpen {
            if markerView.frame.contains(point) {
                // marker tapped
            } else {
                mapView?.viewAnnotations.removeAll()
                isMarkerOpen = false
            }
        }
    }
}

extension DebugViewController: LocationPermissionsDelegate {

}

extension DebugViewController: AnnotationInteractionDelegate {
    public func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
        if let annotation = annotations.first as? PointAnnotation {
            mapView!.viewAnnotations.removeAll()
            isMarkerOpen = false

            addViewAnnotation(annotation: annotation)
        }
    }

    private func addViewAnnotation(annotation: PointAnnotation) {
        print("addViewAnnotation: associatedFeatureId=\(annotation.id)")
        let options = ViewAnnotationOptions(
           geometry: annotation.point,
           width: 100,
           height: 40,
           associatedFeatureId: annotation.id,
           allowOverlap: false,
           anchor: .top,
           offsetY: 50
        )

        exitName = annotation.userInfo!["exitName"] as! String
        exitId = annotation.userInfo!["exitId"] as! String
        markerView = createMarkerView()
        markerView!.text = exitName

        do {
            try mapView?.viewAnnotations.add(markerView, options: options)
        } catch {
            print("exception when adding view annotation")
        }
        isMarkerOpen = true
    }

    private func createMarkerView() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .black
        label.backgroundColor = .white
        label.textAlignment = .center
        return label
    }
}

extension DebugViewController: GestureManagerDelegate {
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didBegin gestureType: MapboxMaps.GestureType) {

    }

    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEnd gestureType: MapboxMaps.GestureType, willAnimate: Bool) {
        if gestureType == GestureType.pan {
            locationDragged = true
        }
    }

    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEndAnimatingFor gestureType: MapboxMaps.GestureType) {

    }
}
