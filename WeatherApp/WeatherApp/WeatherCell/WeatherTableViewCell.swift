//
//  WeatherTableViewCell.swift
//  WeatherApp

import UIKit

class WeatherTableViewCell: UITableViewCell {

    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var highTempLabel: UILabel!
    @IBOutlet var lowTempLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    static let identifier = "WeatherTableViewCell" //A reuse identifier is a string that identifies a reusable table view cell. This property allows you to dequeue and reuse the cell when scrolling, which helps improve performance.
    
    static func nib() -> UINib{
        return UINib(nibName:"WeatherTableViewCell", bundle: nil)//This method allows you to load the contents of the nib file at runtime and create instances of the custom cell.
        

    }
    
    func configure(with model: DailyForecast) {
        
        self.highTempLabel.textAlignment = .center
        self.lowTempLabel.textAlignment = .center
        
        self.lowTempLabel.text = "\(Double(model.temperature.minimum.value))°"
        self.highTempLabel.text = "\(Double(model.temperature.maximum.value))°"
        
        //Date label
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        if let date = dateFormatter.date(from: model.date) {
            let calendar = Calendar.current
            let weekdaySymbols = calendar.weekdaySymbols
            let weekday = weekdaySymbols[calendar.component(.weekday, from: date) - 1]
            self.dayLabel.text = weekday
        }
        
        
        //Image
        let imageUrl = "https://developer.accuweather.com/sites/default/files/\(String(format: "%02d", model.day.icon))-s.png"
        let url = URL(string: imageUrl)

        // Create a URLSession data task to download the image data
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            // Check for errors and unwrap the data
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.iconImageView.image = UIImage(data: data)
                self.iconImageView.contentMode = .scaleAspectFit
            }
        }
        
        // Start the data task to download the image
        task.resume()
        
    }
    
}
