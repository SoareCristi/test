//
//  WeatherCollectionViewCell.swift
//  WeatherApp


import UIKit

class WeatherCollectionViewCell: UICollectionViewCell {

    static let identifier = "WeatherCollectionViewCell"

        static func nib() -> UINib {
            return UINib(nibName: "WeatherCollectionViewCell",
                         bundle: nil)
        }

        @IBOutlet var iconImageView: UIImageView!
        @IBOutlet var tempLabel: UILabel!
        @IBOutlet var hourLabel: UILabel!
        
        //configuring the cell with hour label, image and temperature label
        func configure(with model: HourlyForecast) {
            self.tempLabel.text = "\(model.temperature.value)°"
            
            //Creates DateFormatter instances, converts dateTime string to a Date object, and displays the time portion
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let date = dateFormatter.date(from: model.dateTime) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: date)
                self.hourLabel.text = timeString
            }
            
            //Image - weather icon from the AccuWeather website
            //each forecast has a weatherIcon field that returns a number
            let imageUrl = "https://developer.accuweather.com/sites/default/files/\(String(format: "%02d", model.weatherIcon))-s.png"
            let url = URL(string: imageUrl)

            //Create a URLSession data task to download the image data
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
            task.resume()
        }

        override func awakeFromNib() {
            super.awakeFromNib()
        }

}
