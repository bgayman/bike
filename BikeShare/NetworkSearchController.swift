import UIKit

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
            self.animateUpdate(with: oldValue, newDataSource: self.searchResults)
        }
    }
    
    var searchString = ""
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
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.automaticallyAdjustsScrollViewInsets = true
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeTableViewCell
        cell.bikeNetwork = self.searchResults[indexPath.row]
        cell.searchString = self.searchString
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let network = self.searchResults[indexPath.row]
        self.delegate?.didSelect(network: network)
    }
}
