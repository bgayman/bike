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
}

