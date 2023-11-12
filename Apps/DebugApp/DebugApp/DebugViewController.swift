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
    var exits: [MapExit] = []

    // Location
    let locationManager = CLLocationManager()
    var currCoords = CLLocationCoordinate2D(latitude: 40.7608, longitude: -111.8910)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapboxMap()
        setupFilterBtn()

        // load exits
        DispatchQueue.global(qos: .userInteractive).async {
            let decoder = JSONDecoder()
            let exits: [MapExit] = try! decoder.decode([MapExit].self, from: Data(exitJson.utf8))
            DispatchQueue.main.sync { [weak self] in
                self?.exits = exits
                self?.showExits(exits)
            }
        }
    }

    private func setupMapboxMap() {
        let styleURI = StyleURI(rawValue: "mapbox://styles/basebeta/cla1us0xn000314mob3xabfm2")!
        let myMapInitOptions = MapInitOptions(
           styleURI: styleURI
        )

        mapView = MapView(frame: view.bounds)
        guard let mapView = mapView else {
            return
        }

        mapView.mapboxMap.loadStyleURI(styleURI) { [weak self] result in
            self?.mapView!.location.options.activityType = .other
            let configuration = Puck2DConfiguration.makeDefault(showBearing: true)
            self?.mapView!.location.options.puckType = .puck2D(configuration)
            self?.mapView!.location.locationProvider.startUpdatingHeading()
            self?.mapView!.location.locationProvider.startUpdatingLocation()
        }

        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMapTapped(_:))))
        mapView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        let cameraOptions = CameraOptions(
           center: CLLocationCoordinate2D(latitude: currCoords.latitude, longitude: currCoords.longitude),
           zoom: CGFloat(5),
           pitch: CGFloat(0)
        )

        mapView.mapboxMap.setCamera(to: cameraOptions)
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

    private func showExits(_ exitList: [MapExit]) {
        // print("show exits: \(exitList.count)")
        pointAnnotationList.removeAll()
        if pointAnnotationManager != nil {
            mapView!.annotations.removeAnnotationManager(withId: pointAnnotationManager.id)
        }
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.delegate = self

        for exit in exitList {
            let annotation = makeMapAnnotation(exitId: exit._id, name: exit.name, latitude: exit.latitude, longitude: exit.longitude)
            pointAnnotationList[exit._id] = annotation
            pointAnnotationManager.annotations.append(annotation)
        }
    }

    private func makeMapAnnotation(exitId: String, name: String, latitude: Double, longitude: Double) -> PointAnnotation {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        var pointAnnotation = PointAnnotation(coordinate: coordinate)
        let image = UIImage(named: "my-map-marker")!
        pointAnnotation.image = .init(image: image, name: "location_pin")
        pointAnnotation.userInfo = [
            "exitId": exitId,
            "exitName": name
        ]
        return pointAnnotation
    }

    private func setupFilterBtn() {
        let filterButton = UIButton()
        filterButton.setTitle("Simulate filter", for: .normal)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterButton)
        filterButton.backgroundColor = .blue
        filterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        filterButton.addTarget(self, action: #selector(filterClicked), for: .touchUpInside)
    }

    private var isFiltered = false
    @objc private func filterClicked() {
        if !isFiltered {
            let filteredExits = exits.filter { exit in
                Float.random(in: 0..<1) > 0.5
            }
            showExits(filteredExits)
        } else {
            showExits(exits)
        }

        isFiltered = !isFiltered
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

struct MapExit: Codable {
    let _id: String
    let name: String
    let latitude: Double
    let longitude: Double
}