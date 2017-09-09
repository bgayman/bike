import UIKit

//MARK: - BikeTableViewCell
class BikeTableViewCell: UITableViewCell
{
    //MARK: - Constants
    struct Constants
    {
        static let LayoutMargin: CGFloat = 8.0
    }
    
    //MARK: - Properties
    lazy fileprivate var stackView: UIStackView =
    {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel])
        self.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        
        if self.traitCollection.isSmallerDevice
        {
            stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
            stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -Constants.LayoutMargin).isActive = true
        }
        else
        {
            stackView.leadingAnchor.constraint(equalTo: self.contentView.readableContentGuide.leadingAnchor, constant: Constants.LayoutMargin).isActive = true
            stackView.trailingAnchor.constraint(equalTo: self.contentView.readableContentGuide.trailingAnchor, constant: -Constants.LayoutMargin).isActive = true
        }
        stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: Constants.LayoutMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.LayoutMargin).isActive = true
        return stackView
    }()
    
    @objc lazy var titleLabel: UILabel =
    {
        let networkNameLabel = UILabel()
        networkNameLabel.translatesAutoresizingMaskIntoConstraints = false
        networkNameLabel.numberOfLines = 0
        networkNameLabel.lineBreakMode = .byWordWrapping
        return networkNameLabel
    }()
    
    @objc lazy var subtitleLabel: UILabel =
    {
        let networkLocationLabel = UILabel()
        networkLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        networkLocationLabel.numberOfLines = 0
        networkLocationLabel.lineBreakMode = .byWordWrapping
        return networkLocationLabel
    }()
    
    var bikeNetwork: BikeNetwork?
    {
        didSet
        {
            guard let bikeNetwork = self.bikeNetwork else { return }
            guard self.searchString == nil else
            {
                self.configureCell(searchString: self.searchString!)
                return
            }

            self.configureCell(bikeNetwork: bikeNetwork)
        }
    }
    
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = self.bikeStation else { return }
            guard self.searchString == nil else
            {
                self.configureCell(searchString: self.searchString!)
                return
            }
            self.configureCell(bikeStation: bikeStation)
        }
    }
    
    @objc var searchString: String?
    {
        didSet
        {
            guard let searchString = self.searchString else { return }
            self.configureCell(searchString: searchString)
        }
    }
    
    //MARK: - Lifecycle
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        stackView.alignment = .leading
        stackView.spacing = Constants.LayoutMargin
        
        #if !os(tvOS)
            self.contentView.backgroundColor = .app_beige
            self.backgroundColor = .app_beige
            self.separatorInset = UIEdgeInsets(top: 0, left: Constants.LayoutMargin, bottom: 0, right: 0)
            self.titleLabel.font = UIFont.app_font(forTextStyle: .title1)
            self.subtitleLabel.font = UIFont.app_font(forTextStyle: .body)
        #else
            self.titleLabel.font = UIFont.app_font(forTextStyle: .title3)
            self.subtitleLabel.font = UIFont.app_font(forTextStyle: .body)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder")
    }
    
    //MARK: - UI Helpers
    private func configureCell(bikeNetwork: BikeNetwork)
    {
        self.titleLabel.text = bikeNetwork.name
        self.subtitleLabel.text = bikeNetwork.locationDisplayName
    }
    
    private func configureCell(bikeStation: BikeStation)
    {
        let bullet = NSAttributedString(string: "• ", attributes: [NSAttributedStringKey.foregroundColor: bikeStation.pinTintColor, NSAttributedStringKey.font: self.titleLabel.font ?? UIFont.app_font(forTextStyle: .title1)])
        let name = NSAttributedString(string: bikeStation.name)
        self.titleLabel.attributedText = bullet + name
        self.subtitleLabel.text = "\(bikeStation.statusDisplayText)\n\(bikeStation.dateComponentText)"
    }
    
    private func configureCell(searchString: String)
    {
        if let bikeStation = self.bikeStation
        {
            let titleAttribString = NSMutableAttributedString(string: bikeStation.name, attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title1)])
            
            self.titleLabel.attributedText = self.searchHightlighted(attribString: titleAttribString, searchString: searchString)
            self.subtitleLabel.text = "\(bikeStation.statusDisplayText)\n\(bikeStation.dateComponentText)"
        }
        else if let bikeNetwork = self.bikeNetwork
        {
            let titleAttribString = NSMutableAttributedString(string: bikeNetwork.name, attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title1)])
            let subtitleAttribString = NSMutableAttributedString(string: bikeNetwork.locationDisplayName, attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .caption1)])
            
            self.titleLabel.attributedText = self.searchHightlighted(attribString: titleAttribString, searchString: searchString)
            self.subtitleLabel.attributedText = self.searchHightlighted(attribString: subtitleAttribString, searchString: searchString)
        }
        else
        {
            let titleAttribString = NSMutableAttributedString(string: self.titleLabel.text ?? "", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .body)])
            let subtitleAttribString = NSMutableAttributedString(string: self.subtitleLabel.text ?? "", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .caption1)])
            
            self.titleLabel.attributedText = self.searchHightlighted(attribString: titleAttribString, searchString: searchString)
            self.subtitleLabel.attributedText = self.searchHightlighted(attribString: subtitleAttribString, searchString: searchString)
        }
        
    }
    
    private func searchHightlighted(attribString: NSMutableAttributedString, searchString: String) -> NSAttributedString
    {
        let range = (attribString.string.lowercased() as NSString).range(of: searchString.lowercased())
        attribString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.app_blue], range: range)
        return attribString
    }
}

