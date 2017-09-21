
import UIKit
import Dwifft

//MARK: - NetworkSearchControllerDelegate
protocol NetworkSearchControllerDelegate: class
{
    func didSelect(network: BikeNetwork)
}

//MARK: - NetworkSearchController
class NetworkSearchController: UITableViewController
{
    //MARK: - Properties
    var all = [BikeNetwork]()
    var searchResults = [BikeNetwork]()
    {
        didSet
        {
            var mutable = [(String, [BikeNetwork])]()
            mutable.append(("Networks", searchResults.map
            { bikeNetwork in
                var bikeNetwork = bikeNetwork
                bikeNetwork.searchString = searchString
                return bikeNetwork
            }))
            diffCalculator.sectionedValues = SectionedValues(mutable)
        }
    }
    
    lazy fileprivate var diffCalculator: TableViewDiffCalculator<String, BikeNetwork> =
    {
        let diffCalculator = TableViewDiffCalculator<String, BikeNetwork>(tableView: self.tableView)
        diffCalculator.insertionAnimation = .top
        diffCalculator.deletionAnimation = .bottom
        return diffCalculator
    }()
    
    @objc var searchString = ""
    {
        didSet
        {
            self.searchResults = self.all.filter
            { network in
                
                return network.name.lowercased().contains(self.searchString.lowercased()) || network.locationDisplayName.lowercased().contains(self.searchString.lowercased())
            }
            
        }
    }
    
    weak var delegate: NetworkSearchControllerDelegate?
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = .app_beige
        let nib = UINib(nibName: "\(BikeNetworkTableViewCell.self)", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "Cell")
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        #if !os(tvOS)
            self.tableView.dragDelegate = self
        #endif
    }
    
    //MARK: - TableView
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return diffCalculator.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return diffCalculator.numberOfObjects(inSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeNetworkTableViewCell
        cell.bikeNetwork = diffCalculator.value(atIndexPath: indexPath)
        cell.searchString = self.searchString
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let network = self.searchResults[indexPath.row]
        self.delegate?.didSelect(network: network)
    }
    
    #if !os(tvOS)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let favorite: UITableViewRowAction
        if let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork,
            homeNetwork.id == self.searchResults[indexPath.row].id
        {
            favorite = UITableViewRowAction(style: .default, title: "★")
            { (_, _) in
                UserDefaults.bikeShareGroup.setHomeNetwork(nil)
                #if os(iOS) || os(watchOS)
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: NSNull() as AnyObject])
                #endif
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        else
        {
            favorite = UITableViewRowAction(style: .default, title: "☆")
            { (_, indexPath) in
                let network = self.searchResults[indexPath.row]
                UserDefaults.bikeShareGroup.setHomeNetwork(network)
                #if os(iOS) || os(watchOS)
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: network.jsonDict as AnyObject])
                #endif
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        favorite.backgroundColor = UIColor.app_blue
                
        let share = UITableViewRowAction(style: .default, title: "Share")
        { [unowned self] (_, indexPath) in
            let cell = tableView.cellForRow(at: indexPath)
            let rect = tableView.rectForRow(at: indexPath)
            let network = self.searchResults[indexPath.row]
            guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.id)") else { return }
            
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController
            {
                presenter.sourceRect = rect
                presenter.sourceView = cell
            }
            self.present(activityViewController, animated: true)
        }
        share.backgroundColor = UIColor.app_green
        return [favorite, share]
    }
    #endif
}

// MARK: - UITableViewDragDelegate
#if !os(tvOS)
    extension NetworkSearchController: UITableViewDragDelegate
    {
        func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
        {
            let network = self.searchResults[indexPath.row]
            guard let url = URL(string: "\(Constants.WebSiteDomain)/stations/\(network.id)") else { return [] }
            let dragURLItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
            let dragStringItem = UIDragItem(itemProvider: NSItemProvider(object: "\(network.name)" as NSString))
            return [dragURLItem, dragStringItem]
        }
    }
#endif
