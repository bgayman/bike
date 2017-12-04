//
//  BikeStationDetailViewController.swift
//  BikeShare
//
//  Created by B Gay on 9/10/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit
import CoreSpotlight
import MobileCoreServices
import Charts

// MARK: - BikeStationDetailViewController

class BikeStationDetailViewController: UIViewController
{
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var graphLabel: UILabel!
    @IBOutlet weak var graphActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionLabelBottomConstrant: NSLayoutConstraint!
    @IBOutlet weak var graphVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timeDistanceLabel: UILabel!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet weak var collectionViewVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var nearbyStationsLabel: UILabel!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var graphContainerView: UIView!
    
    // MARK: - Properties
    let bikeNetwork: BikeNetwork
    var bikeStation: BikeStation
    {
        didSet
        {
            updateUI()
        }
    }
    var bikeStations: [BikeStation]
    var closebyStations = [BikeStation]()
    let labelAlpha: CGFloat = 0.70
    var hasGraph: Bool
    var titleLabelTopOffset: CGFloat = 0.0
    var isFirstLoad = true
    var stationStatuses: [BikeStationStatus]?
    {
        didSet
        {
            guard self.stationStatuses != nil else
            {
                self.hasGraph = false
                return
            }
            let bikeStationStatus = BikeStationStatus(numberOfBikesAvailable: self.bikeStation.freeBikes ?? 0,
                                                      stationID: self.bikeStation.id,
                                                      id: 0,
                                                      networkID: self.bikeNetwork.id,
                                                      timestamp: Date(),
                                                      numberOfDocksDisabled: self.bikeStation.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled,
                                                      numberOfDocksAvailable: self.bikeStation.emptySlots,
                                                      numberOfBikesDisabled: self.bikeStation.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled,
                                                      isRenting: self.bikeStation.gbfsStationInformation?.stationStatus?.isRenting,
                                                      isReturning: self.bikeStation.gbfsStationInformation?.stationStatus?.isReturning,
                                                      isInstalled: self.bikeStation.gbfsStationInformation?.stationStatus?.isInstalled)
            self.stationStatuses?.append(bikeStationStatus)
            updateChartData()
        }
    }
    
    override var keyCommands: [UIKeyCommand]?
    {
        let share = UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(self.didPressAction), discoverabilityTitle: "Share")
        let back = UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(self.back), discoverabilityTitle: "Back")
        let refresh = UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(self.fetchStations), discoverabilityTitle: "Refresh")
        return [share, back, refresh]
    }
    
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    override var previewActionItems: [UIPreviewActionItem]
    {
        let shareActionItem = UIPreviewAction(title: "Share", style: .default)
        { _, viewController in
            guard let viewController = viewController as? BikeStationDetailViewController,
                let url = URL(string: "\(Constants.WebSiteDomain)/network/\(viewController.bikeNetwork.id)/station/\(viewController.bikeStation.id)")
                else { return }
            let activity = ActivityViewCustomActivity.stationFavoriteActivity(station: self.bikeStation, network: self.bikeNetwork)
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: [activity])
            UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
        }
        let mapsActionItem = UIPreviewAction(title: "Open in Maps", style: .default)
        { _, viewController in
            guard let viewController = viewController as? BikeStationDetailViewController
                else { return }
            viewController.openMapBikeStationInMaps(MapBikeStation(bikeStation: viewController.bikeStation))
        }
        let favorite = UIPreviewAction(title: "☆", style: .default)
        { [unowned self] _, viewController in
            guard let viewController = viewController as? BikeStationDetailViewController
                else { return }
            let station = viewController.bikeStation
            var favedStations = UserDefaults.bikeShareGroup.favoriteStations(for: self.bikeNetwork)
            favedStations.append(station)
            let jsonDicts = favedStations.map { $0.jsonDict }
            try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [self.bikeNetwork.id: jsonDicts as AnyObject])
            UserDefaults.bikeShareGroup.setFavoriteStations(for: self.bikeNetwork, favorites: favedStations)
        }
        let unfavorite = UIPreviewAction(title: "★", style: .default)
        { [unowned self] _, viewController in
            guard let viewController = viewController as? StationDetailViewController
                else { return }
            let station = viewController.station
            var favedStations = UserDefaults.bikeShareGroup.favoriteStations(for: self.bikeNetwork)
            let favedS = favedStations.filter { $0.id == station.id }.last
            guard let favedStation = favedS,
                let index = favedStations.index(of: favedStation) else { return }
            favedStations.remove(at: index)
            let jsonDicts = favedStations.map { $0.jsonDict }
            try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [self.bikeNetwork.id: jsonDicts as AnyObject])
            UserDefaults.bikeShareGroup.setFavoriteStations(for: self.bikeNetwork, favorites: favedStations)
        }
        
        return UserDefaults.bikeShareGroup.favoriteStations(for: self.bikeNetwork).contains(where: { $0.id == self.bikeStation.id }) ? [shareActionItem, mapsActionItem, unfavorite] : [shareActionItem, mapsActionItem, favorite]
    }
    
    lazy var gradientLayer: CAGradientLayer =
    {
        let gradientLayer = CAGradientLayer()
        let firstColor = UIColor.app_brown.withAlphaComponent(0.05)
        let secondColor = UIColor.app_brown.withAlphaComponent(0.5)
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor]
        return gradientLayer
    }()
    
    lazy var scrollView: BikeStationDetailScrollView =
    {
        let scrollView = BikeStationDetailScrollView(frame: CGRect(x: 0, y: self.view.safeAreaInsets.top, width: self.view.bounds.width, height: 150.0))
        self.view.insertSubview(scrollView, belowSubview: self.pageControl)
        scrollView.addSubview(stackView)
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        return scrollView
    }()
    
    lazy var doneButton: UIBarButtonItem =
    {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone))
        doneButton.isSpringLoaded = true
        return doneButton
    }()
    
    @objc lazy var actionBarButton: UIBarButtonItem =
    {
        let actionBarButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.didPressAction))
        return actionBarButton
    }()
    
    // MARK: - Lifecycle
    init(with bikeNetwork: BikeNetwork, station: BikeStation, stations: [BikeStation], hasGraph: Bool)
    {
        self.bikeNetwork = bikeNetwork
        self.bikeStation = station
        self.bikeStations = stations
        self.hasGraph = hasGraph
        super.init(nibName: "\(BikeStationDetailViewController.self)", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        styleViews()
        addQuickAction()
        addToSpotlight()
        fetchStations()
        fetchHistory()
        scrollView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        scrollView.frame = CGRect(x: 0.0, y: self.view.safeAreaInsets.top, width: self.view.bounds.width, height: 150.0)
        gradientLayer.frame = overlayView.bounds
        if hasGraph
        {
            scrollView.contentSize = CGSize(width: view.bounds.width, height: 3 * 150.0)
            scrollView.setContentOffset(CGPoint(x: 0.0, y: 150.0), animated: false)
            stackView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: (self.view.bounds.height - self.view.safeAreaInsets.top) + 300.0)
        }
        else
        {
            scrollView.contentSize = CGSize(width: view.bounds.width, height: 2 * 150.0)
            stackView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: (self.view.bounds.height - self.view.safeAreaInsets.top) + 150.0)
        }
        
        if self.traitCollection.isSmallerDevice
        {
            titleLabel.font = UIFont.systemFont(ofSize: 65.0, weight: .heavy)
            graphLabel.font = UIFont.systemFont(ofSize: 65.0, weight: .heavy)
            networkLabel.font = UIFont.systemFont(ofSize: 65.0, weight: .heavy)
        }
        else
        {
            titleLabel.font = UIFont.systemFont(ofSize: 90.0, weight: .heavy)
            graphLabel.font = UIFont.systemFont(ofSize: 90.0, weight: .heavy)
            networkLabel.font = UIFont.systemFont(ofSize: 90.0, weight: .heavy)
        }
        titleLabel.attributedText = bikeStation.statusDetailAttributedString(for: titleLabel.font)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        animateViewsOn()
    }
    
    // MARK: - Setup
    private func styleViews()
    {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationItem.rightBarButtonItem = actionBarButton
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        titleLabel.alpha = labelAlpha
        titleLabel.textColor = .black
        networkLabel.text = bikeNetwork.name
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 35.0, weight: .heavy)
        descriptionLabel.alpha = labelAlpha
        descriptionLabel.textColor = .white
        descriptionLabel.text = BikeStationDescriptionGenerator.descriptionMessage(for: bikeStation)
        
        nearbyStationsLabel.font = UIFont.systemFont(ofSize: 35.0, weight: .heavy)
        nearbyStationsLabel.textColor = .white
        
        timeDistanceLabel.font = UIFont.app_font(forTextStyle: .title2, weight: .semibold)
        timeDistanceLabel.alpha = labelAlpha
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "marker")
        
        pageControl.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        pageControl.currentPageIndicatorTintColor = UIColor.app_blue
        pageControl.pageIndicatorTintColor = UIColor.white
                
        let nib = UINib(nibName: "\(BikeStationCollectionViewCell.self)", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "Cell")
        collectionView.dragDelegate = self
        collectionView.dragInteractionEnabled = true
        scrollView.panGestureRecognizer.require(toFail: collectionView.panGestureRecognizer)
        
        graphContainerView.isHidden = !hasGraph
        lineChartView.isHidden = true
        
        setupChartView()
        setupAnimationTransforms()
        setupGradientLayer()
        updateUI()
        
        if !self.traitCollection.isSmallerDevice
        {
            self.navigationItem.leftBarButtonItem = self.doneButton
        }
        
        if self.traitCollection.forceTouchCapability == .available
        {
            self.registerForPreviewing(with: self, sourceView: self.view)
        }
    }
    
    private func setupGradientLayer()
    {
        overlayView.layer.addSublayer(gradientLayer)
    }
    
    private func setupAnimationTransforms()
    {
        titleLabel.transform = CGAffineTransform(translationX: 300.0, y: 0.0)
        timeDistanceLabel.transform = CGAffineTransform(translationX: 300.0, y: 0.0)
        descriptionLabel.transform = CGAffineTransform(translationX: -700.0, y: 0.0)
    }
    
    private func setupChartView()
    {
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.legend.enabled = false
        lineChartView.legend.form = .line
        lineChartView.chartDescription?.enabled = true
        lineChartView.chartDescription?.text = "Free Bikes"
        lineChartView.chartDescription?.textColor = .gray
        lineChartView.chartDescription?.font = UIFont.app_font(forTextStyle: .caption1)
        lineChartView.pinchZoomEnabled = false
        
        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.app_font(forTextStyle: .caption1)
        xAxis.labelTextColor = .gray
        xAxis.granularity = 3600.0 * 24
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.valueFormatter = DateValueFormatter()
        
        let leftAxis = lineChartView.leftAxis
        leftAxis.labelPosition = .outsideChart
        leftAxis.labelFont = UIFont.app_font(forTextStyle: .caption1)
        leftAxis.labelTextColor = .gray
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawAxisLineEnabled = true
        leftAxis.axisMinimum = 0.0
        leftAxis.drawLabelsEnabled = true
        
        lineChartView.rightAxis.enabled = false
        lineChartView.isUserInteractionEnabled = false
    }
    
    // MARK: - Update
    private func updateUI()
    {
        title = bikeStation.name
        titleLabel.attributedText = bikeStation.statusDetailAttributedString(for: titleLabel.font)
        timeDistanceLabel.text = "\(bikeStation.dateComponentText) | \(bikeStation.distanceDescription)"
        
        if hasGraph
        {
            pageControl.numberOfPages = 3
            pageControl.currentPage = 1
            titleLabelTopOffset = titleLabelTopConstraint.constant
        }
        else
        {
            titleLabelTopOffset = titleLabelTopConstraint.constant
            pageControl.numberOfPages = 2
            pageControl.currentPage = 0
        }
        closebyStations = closebyStations(for: bikeStations)
        collectionView.reloadData()
        
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MapBikeStation(bikeStation: bikeStation)
        mapView.addAnnotation(annotation)
        if isFirstLoad
        {
            isFirstLoad = false
            mapView.showAnnotations([annotation], animated: false)
        }
        
    }
    
    private func updateChartData()
    {
        guard let stationStatues: [BikeStationStatus] = self.stationStatuses else { return }
        let sortedStatues = stationStatues.sorted { $0.timestamp < $1.timestamp }
        let data: [ChartDataEntry] = sortedStatues.map { ChartDataEntry(x: $0.timestamp.timeIntervalSince1970, y: Double($0.numberOfBikesAvailable)) }
        
        let set = LineChartDataSet(values: data, label: "Free Bikes")
        set.setColor(UIColor.app_blue)
        set.axisDependency = .left
        set.valueTextColor = UIColor.app_blue
        set.fillColor = UIColor.app_blue
        set.drawFilledEnabled = false
        set.drawCirclesEnabled = false
        set.drawCircleHoleEnabled = false
        set.drawValuesEnabled = false
        set.fillAlpha = 0.80
        set.lineWidth = 1.5
        set.highlightColor = UIColor.app_blue
        set.visible = true
        
        let chartData = LineChartData(dataSet: set)
        chartData.setValueTextColor(.white)
        chartData.setValueFont(UIFont.app_font(forTextStyle: .body))
        
        self.lineChartView.doubleTapToZoomEnabled = false
        self.lineChartView.data = chartData
        self.lineChartView.isHidden = false
    }
    
    private func animateViewsOn()
    {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.titleLabel.transform = .identity
        })
        UIView.animate(withDuration: 0.5, delay: 0.02, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.timeDistanceLabel.transform = .identity
        })
        UIView.animate(withDuration: 0.5, delay: 0.04, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.descriptionLabel.transform = .identity
        })
    }
    
    fileprivate func closebyStations(for stations: [BikeStation]) -> [BikeStation]
    {
        let sortedStations = stations.sorted{ $0.distance(to: self.bikeStation) < $1.distance(to: self.bikeStation) }
        let closebyStations = Array(sortedStations.prefix(8))
        return closebyStations
    }
    
    // MARK: - Actions
    @objc func didPressAction()
    {
        guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(self.bikeNetwork.id)/station/\(self.bikeStation.id)") else { return }
        
        let customActivity = ActivityViewCustomActivity.stationFavoriteActivity(station: self.bikeStation, network: self.bikeNetwork)
        let openMapsActivity = ActivityViewCustomActivity.openMapsActivity(station: bikeStation)
        
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: [customActivity, openMapsActivity])
        if let presenter = activityController.popoverPresentationController
        {
            presenter.barButtonItem = self.actionBarButton
        }
        self.present(activityController, animated: true)
    }
    
    @objc func didPressDone()
    {
        self.dismiss(animated: true)
    }
    
    @objc func back()
    {
        if self.presentingViewController != nil
        {
            self.didPressDone()
        }
        else
        {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Networking
    private func fetchHistory()
    {
        self.setNetworkActivityIndicator(shown: true)
        self.graphActivityIndicator.startAnimating()
        let stationsClient = StationsClient()
        stationsClient.fetchStationStatuses(with: self.bikeNetwork.id, stationID: self.bikeStation.id)
        { (response) in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                    self.setNetworkActivityIndicator(shown: false)
                    self.graphActivityIndicator.stopAnimating()
                #endif
                stationsClient.invalidate()
                switch response
                {
                case .error:
                    self.graphActivityIndicator.isHidden = true
                    self.lineChartView.isHidden = false
                case .success(let statuses):
                    self.stationStatuses = statuses
                }
            }
        }
    }
    
    @objc func fetchStations()
    {
        self.setNetworkActivityIndicator(shown: true)
        let stationsClient = StationsClient()
        stationsClient.fetchStations(with: self.bikeNetwork, fetchGBFSProperties: true)
        { response in
            DispatchQueue.main.async
            {
                self.setNetworkActivityIndicator(shown: false)
                self.navigationItem.prompt = nil
                stationsClient.invalidate()
                switch response
                {
                case .error(let errorMessage):
                    let alert = UIAlertController(errorMessage: errorMessage)
                    alert.modalPresentationStyle = .overFullScreen
                    self.present(alert, animated: true)
                case .success(var stations):
                    guard !stations.isEmpty else
                    {
                        let alert = UIAlertController(errorMessage: "Uh oh, looks like there are no stations for this network.\n\nThis might be for seasonal reasons or this network might no longer exist 😢.")
                        alert.modalPresentationStyle = .overFullScreen
                        self.present(alert, animated: true)
                        return
                    }
                    if let bikeStation = stations.first(where: { $0.id == self.bikeStation.id })
                    {
                        let index = stations.index(of: bikeStation)!
                        stations.remove(at: index)
                        self.bikeStations = stations
                        self.closebyStations = self.closebyStations(for: self.bikeStations)
                        self.bikeStation = bikeStation

                    }
                }
            }
        }
    }
    
    @objc func setNetworkActivityIndicator(shown: Bool)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = shown
    }
}

// MARK: - UICollectionViewDelegate / UICollectionViewDataSource
extension BikeStationDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return closebyStations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! BikeStationCollectionViewCell
        cell.bikeStation = closebyStations[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let station = closebyStations[indexPath.item]
        let bikeStationDetailViewController = BikeStationDetailViewController(with: bikeNetwork, station: station, stations: bikeStations, hasGraph: hasGraph)
        self.navigationController?.pushViewController(bikeStationDetailViewController, animated: true)
        
    }
}

// MARK: - UICollectionViewDragDelegate
extension BikeStationDetailViewController: UICollectionViewDragDelegate
{
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
    {
        let station = self.closebyStations[indexPath.item]
        guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(self.bikeNetwork.id)/station/\(station.id)") else { return [] }
        let dragURLItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
        return [dragURLItem]
    }
}

// MARK: - MKMapViewDelegate
extension BikeStationDetailViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard let mapBikeStation = annotation as? MapBikeStation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "marker", for: annotation) as? MKMarkerAnnotationView
        view?.markerTintColor = mapBikeStation.bikeStation.pinTintColor
        return view
    }
}

// MARK: - UIScrollViewDelegate
extension BikeStationDetailViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        guard scrollView == self.scrollView else { return }
        
        if hasGraph && scrollView.contentOffset.y < 150.0
        {
            let progress = (150.0 - scrollView.contentOffset.y) / 150.0
            titleLabel.alpha = labelAlpha - (progress * labelAlpha)
            timeDistanceLabel.alpha = labelAlpha - (progress * labelAlpha)
            graphLabel.alpha = progress * labelAlpha
            lineChartView.alpha = progress
            graphActivityIndicator.alpha = progress
            graphVisualEffectView.alpha = progress
            pageControl.currentPage = scrollView.contentOffset.y < 150.0 / 2.0 ? 0 : 1
            descriptionLabelBottomConstrant.constant = 30.0 + 150.0 * progress
        }
        else if !hasGraph && scrollView.contentOffset.y > 0.0
        {
            let progress = scrollView.contentOffset.y / 150.0
            titleLabelTopConstraint.constant = titleLabelTopOffset + 150.0 * progress
            descriptionLabel.alpha = labelAlpha - (progress * labelAlpha)
            nearbyStationsLabel.alpha = (progress * labelAlpha)
            titleLabel.alpha = labelAlpha - (progress * labelAlpha)
            timeDistanceLabel.alpha = labelAlpha - (progress * labelAlpha)
            networkLabel.alpha = (progress * labelAlpha)
            pageControl.currentPage = scrollView.contentOffset.y > 150.0 / 2.0 ? 1 : 0
        }
        else if hasGraph && scrollView.contentOffset.y > 150.0
        {
            let progress = (scrollView.contentOffset.y - 150.0) / 150.0
            titleLabelTopConstraint.constant = titleLabelTopOffset + 150.0 * progress
            descriptionLabel.alpha = labelAlpha - (progress * labelAlpha)
            nearbyStationsLabel.alpha = (progress * labelAlpha)
            titleLabel.alpha = labelAlpha - (progress * labelAlpha)
            timeDistanceLabel.alpha = labelAlpha - (progress * labelAlpha)
            networkLabel.alpha = (progress * labelAlpha)
            pageControl.currentPage = progress > 0.5 ? 2 : 1
        }
    }
}

// MARK: - Indexing
private extension BikeStationDetailViewController
{
    func addToSpotlight()
    {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeURL as String)
        attributeSet.title = self.bikeStation.name
        attributeSet.contentDescription = self.bikeNetwork.name
        let id = "bikeshare://network/\(self.bikeNetwork.id)/station/\(self.bikeStation.id)"
        let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: "com.bradgayman.bikeshare", attributeSet: attributeSet)
        
        item.expirationDate = Date.distantFuture
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id])
        { _ in
            CSSearchableIndex.default().indexSearchableItems([item])
            { error in
                if let error = error
                {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    //MARK: - QuickAction
    @objc func addQuickAction()
    {
        var quickActions = UIApplication.shared.shortcutItems ?? [UIApplicationShortcutItem]()
        for quickAction in quickActions
        {
            guard quickAction.localizedTitle != self.bikeStation.name else
            {
                return
            }
        }
        if quickActions.count >= 4
        {
            quickActions = Array(quickActions.dropFirst())
        }
        let shortcut = UIApplicationShortcutItem(type: "station", localizedTitle: self.bikeStation.name, localizedSubtitle: self.bikeNetwork.name, icon:UIApplicationShortcutIcon(templateImageName: "bicycle"), userInfo: ["deeplink": "bikeshare://network/\(self.bikeNetwork.id)/station/\(self.bikeStation.id)"])
        quickActions.append(shortcut)
        UIApplication.shared.shortcutItems = quickActions
    }
    
    @objc func openMapBikeStationInMaps(_ mapBikeStation: MapBikeStation)
    {
        let placemark = MKPlacemark(coordinate: mapBikeStation.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = mapBikeStation.title
        mapItem.openInMaps(launchOptions: nil)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension BikeStationDetailViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        let location = view.convert(location, to: collectionView)
        guard let indexPath = self.collectionView.indexPathForItem(at: location) else { return nil }
        let station = self.closebyStations[indexPath.row]
        
        let bikeStationDetailViewController = BikeStationDetailViewController(with: bikeNetwork, station: station, stations: bikeStations, hasGraph: hasGraph)
        
        let rect = view.convert(self.collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame ?? .zero, from: collectionView)
        previewingContext.sourceRect = rect
        return bikeStationDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}

//MARK: - Distance
fileprivate extension BikeStation
{
    func distance(to station: BikeStation) -> CLLocationDistance
    {
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let otherStationLocation = CLLocation(latitude: station.coordinates.latitude, longitude: station.coordinates.longitude)
        return stationLocation.distance(from: otherStationLocation)
    }
}
