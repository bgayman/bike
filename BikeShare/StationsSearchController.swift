import UIKit

//MARK: - StationsSearchControllerDelegate
protocol StationsSearchControllerDelegate: class
{
    func didSelect(station: BikeStation)
}

//MARK: - StationsSearchController
class StationsSearchController: UITableViewController
{
    //MARK: - Properties
    var network: BikeNetwork?
    var all = [BikeStation]()
    var searchResults = [BikeStation]()
    {
        didSet
        {
            self.animateUpdate(with: oldValue, newDataSource: self.searchResults)
        }
    }
    
    var searchString = ""
    {
        didSet
        {
            guard !searchString.isEmpty else
            {
                self.searchResults = self.all
                return
            }
            self.searchResults = self.all.filter
            { station in
                
                return station.name.lowercased().contains(self.searchString.lowercased())
            }
        }
    }
    
    weak var delegate: StationsSearchControllerDelegate?
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.app_beige
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeTableViewCell
        cell.bikeStation = self.searchResults[indexPath.row]
        cell.searchString = self.searchString
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let station = self.searchResults[indexPath.row]
        self.delegate?.didSelect(station: station)
    }
    
    #if !os(tvOS)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        guard let network = self.network else { return nil }
        let s = self.searchResults[indexPath.row]
        let share = UITableViewRowAction(style: .default, title: "Share")
        { [unowned self] (_, indexPath) in
            let cell = tableView.cellForRow(at: indexPath)
            let rect = tableView.rectForRow(at: indexPath)
            let station = self.searchResults[indexPath.row]
            guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.id)/station/\(station.id)") else { return }
            
            let activity = ActivityViewCustomActivity.stationFavoriteActivity(station: station, network: network)
            
            let activityViewController = UIActivityViewController(activityItems: [url, station.coordinates], applicationActivities: [activity])
            if let presenter = activityViewController.popoverPresentationController
            {
                presenter.sourceRect = rect
                presenter.sourceView = cell
            }
            self.present(activityViewController, animated: true)
        }
        share.backgroundColor = UIColor.app_green
        let favorite = UITableViewRowAction(style: .default, title: " ☆ ")
        { [unowned self] _, indexPath in
            let station = self.searchResults[indexPath.row]
            var favedStations = UserDefaults.bikeShareGroup.favoriteStations(for: network)
            favedStations.append(station)
            if let network = self.network
            {
                let jsonDicts = favedStations.map { $0.jsonDict }
                try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [network.id: jsonDicts as AnyObject])
            }
            UserDefaults.bikeShareGroup.setFavoriteStations(for: network, favorites: favedStations)
        }
        favorite.backgroundColor = UIColor.app_blue
        
        let unfavorite = UITableViewRowAction(style: .default, title: " ★ ")
        { [unowned self] _, indexPath in
            let station = self.searchResults[indexPath.row]
            var favedStations = UserDefaults.bikeShareGroup.favoriteStations(for: network)
            let favedS = favedStations.filter { $0.id == station.id }.last
            guard let favedStation = favedS,
                let index = favedStations.index(of: favedStation) else { return }
            favedStations.remove(at: index)
            if let network = self.network
            {
                let jsonDicts = favedStations.map { $0.jsonDict }
                try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [network.id: jsonDicts as AnyObject])
            }
            
            UserDefaults.bikeShareGroup.setFavoriteStations(for: network, favorites: favedStations)
        }
        unfavorite.backgroundColor = UIColor.app_blue
        
        return UserDefaults.bikeShareGroup.favoriteStations(for: network).contains(where: { $0.id == s.id }) ? [share, unfavorite] : [share, favorite]
    }
    #endif
}

