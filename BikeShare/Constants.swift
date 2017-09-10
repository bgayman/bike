import Foundation

typealias JSONDictionary = [String: Any]

struct Constants
{
    static let dateFormatter: DateFormatter =
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()
    
    static let dateComponentsFormatter: DateComponentsFormatter =
    {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.unitsStyle = .full
        dateComponentsFormatter.includesApproximationPhrase = true
        dateComponentsFormatter.maximumUnitCount = 1
        dateComponentsFormatter.allowedUnits = [.month, .day, .hour, .minute, .second]
        return dateComponentsFormatter
    }()
    
    static let measurementFormatter: MeasurementFormatter =
    {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .short
        measurementFormatter.numberFormatter.roundingMode = .halfUp
        measurementFormatter.numberFormatter.maximumFractionDigits = 1
        measurementFormatter.numberFormatter.minimumFractionDigits = 0
        return measurementFormatter
    }()
    
    static let numberFormatter: NumberFormatter =
    {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    static let DidUpdatedUserLocationNotification = "DidUpdatedUserLocationNotification"
    static let AppGroupName = "group.com.bradgayman.bikeshare"
    static let HomeNetworkKey = "homeNetworkKey"
    static let NetworksKey = "networks"
    static let LocationLatitudeKey = "latitude"
    static let LocationLongitudeKey = "longitude"
    static let WebSiteDomain = "https://bike-share.mybluemix.net"
    static let ClosebyStations = "closebyStations"
    static let PreviouslySelectedNetwork = "PreviouslySelectedNetwork"
    static let HasSeenWelcomeScreen = "HasSeenWelcomeScreen"
}

