//
//  ViewController.swift
//  WeatherProject

import UIKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate{

    @IBOutlet var table: UITableView!
    
    var dailyModels = [DailyForecast]()
    var hourlyModels = [HourlyForecast]()
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.register(HourlyTableViewCell.nib(), forCellReuseIdentifier: HourlyTableViewCell.identifier)
        //table.register(WeatherTableViewCell.nib(), forCellReuseIdentifier: WeatherTableViewCell.identifier)
        
        table.delegate = self
        table.dataSource = self
        
        table.backgroundColor = UIColor(red: 227/255.0, green: 244/255.0, blue: 254/255.0, alpha: 0.5)
        view.backgroundColor = UIColor(red: 227/255.0, green: 244/255.0, blue: 254/255.0, alpha: 1.0)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLocation()
    }
    
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, currentLocation == nil  {
            currentLocation = locations.first
            locationManager.stopUpdatingLocation()
            requestWeather()
        }
    }
    
    func requestWeather() {
        
        guard let currentLocation = currentLocation else {
            return
        }

        let long = currentLocation.coordinate.longitude
        let lat = currentLocation.coordinate.latitude
        
        //AccuWeather API key
        let apiKey = "ZA24CgIJ2YD5HA6l5aUdSXQSj7NfaUZp"
        
        //API Requests using URLSession
        
        //Get location key using geoposition search API
        let geoUrl = "https://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=\(apiKey)&q=\(lat),\(long)"
        URLSession.shared.dataTask(with: URL(string: geoUrl)!) { (data, response, error) in
            guard let data = data, error == nil else {
                print("something went wrong")
                return
            }
            var locationKey: String?
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                //location key
                if let dict = json as? [String: Any], let key = dict["Key"] as? String {
                    locationKey = key
                }
                
                
            } catch {
                print("Error decoding location data: \(error)")
            }
            
            guard let locKey = locationKey else {
                print("could not get location key")
                return
            }
            
            
            //Get forecast for 12 hours
            let hourlyUrl = "https://dataservice.accuweather.com/forecasts/v1/hourly/12hour/\(locKey)?apikey=\(apiKey)&metric=true"
            URLSession.shared.dataTask(with: URL(string: hourlyUrl)!) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("something went wrong")
                    return
                }
                var hourly: [HourlyForecast]?
                do {
                    hourly = try JSONDecoder().decode([HourlyForecast].self, from: data)
                } catch {
                    print("error: \(error)")
                }
                
                guard let hourlyForecasts = hourly else {
                    print("could not get hourly forecasts")
                    return
                }
                
                // Get forecast for 5 days
                let dailyUrl = "https://dataservice.accuweather.com/forecasts/v1/daily/5day/\(locKey)?apikey=\(apiKey)&metric=true"
                URLSession.shared.dataTask(with: URL(string: dailyUrl)!) { (data, response, error) in
                    guard let data = data, error == nil else {
                        print("something went wrong")
                        return
                    }
                    var daily: FiveDaysForecast?
                    do {
                        daily = try JSONDecoder().decode(FiveDaysForecast.self, from: data)
                    } catch {
                        print("error: \(error)")
                    }
                    
                    guard let dailyForecasts = daily?.dailyForecasts else {
                        print("could not get daily forecasts")
                        return
                    }
                
                    
                    self.dailyModels.append(contentsOf: dailyForecasts)

                    self.hourlyModels = hourlyForecasts
                    // Update UI
                    DispatchQueue.main.async {
                        // do something with hourlyForecasts and dailyForecasts
                        DispatchQueue.main.async {
                            self.table.reloadData()
                        }
                    }
                }.resume()
            }.resume()
        }.resume()
    }
    
    //Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // 1 cell that is collectiontableviewcell
            return 1
        }
        // return dailyModels count
        return dailyModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: HourlyTableViewCell.identifier, for: indexPath) as! HourlyTableViewCell
            cell.configure(with: hourlyModels)
            cell.backgroundColor = UIColor(red: 227/255.0, green: 244/255.0, blue: 254/255.0, alpha: 0.5)
            return cell
        }

        // Continue
        let cell = tableView.dequeueReusableCell(withIdentifier: WeatherTableViewCell.identifier, for: indexPath) as! WeatherTableViewCell
        cell.configure(with: dailyModels[indexPath.row])
        cell.backgroundColor = UIColor(red: 227/255.0, green: 244/255.0, blue: 254/255.0, alpha: 0.5)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

}

//Codable struct object to store the data from the requests with JSONDecoder


//HourlyForecast
struct HourlyForecast: Codable {
    let dateTime: String
    let epochDateTime: Int
    let weatherIcon: Int
    let iconPhrase: String
    let hasPrecipitation: Bool
    let precipitationType: String?
    let precipitationIntensity: String?
    let isDaylight: Bool
    let temperature: Temperature
    let precipitationProbability: Int
    let mobileLink: String
    let link: String
    
    enum CodingKeys: String, CodingKey {
        case dateTime = "DateTime"
        case epochDateTime = "EpochDateTime"
        case weatherIcon = "WeatherIcon"
        case iconPhrase = "IconPhrase"
        case hasPrecipitation = "HasPrecipitation"
        case precipitationType = "PrecipitationType"
        case precipitationIntensity = "PrecipitationIntensity"
        case isDaylight = "IsDaylight"
        case temperature = "Temperature"
        case precipitationProbability = "PrecipitationProbability"
        case mobileLink = "MobileLink"
        case link = "Link"
    }
}

struct Temperature: Codable {
    let value: Double
    let unit: String
    let unitType: Int
    
    enum CodingKeys: String, CodingKey {
        case value = "Value"
        case unit = "Unit"
        case unitType = "UnitType"
    }
}

//DailyForecast
struct FiveDaysForecast: Codable {
    let headline: Headline
    let dailyForecasts: [DailyForecast]

    enum CodingKeys: String, CodingKey {
        case headline = "Headline"
        case dailyForecasts = "DailyForecasts"
    }
}

struct Headline: Codable {
    let effectiveDate: String
    let effectiveEpochDate: Int
    let severity: Int
    let text: String
    let category: String
    let endDate: String?
    let endEpochDate: Int?
    let mobileLink: String
    let link: String

    enum CodingKeys: String, CodingKey {
        case effectiveDate = "EffectiveDate"
        case effectiveEpochDate = "EffectiveEpochDate"
        case severity = "Severity"
        case text = "Text"
        case category = "Category"
        case endDate = "EndDate"
        case endEpochDate = "EndEpochDate"
        case mobileLink = "MobileLink"
        case link = "Link"
    }
}

struct DailyForecast: Codable {
    let date: String
    let epochDate: Int
    let temperature: TemperatureDaily
    let day: Day
    let night: Night
    let sources: [String]
    let mobileLink: String
    let link: String

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case epochDate = "EpochDate"
        case temperature = "Temperature"
        case day = "Day"
        case night = "Night"
        case sources = "Sources"
        case mobileLink = "MobileLink"
        case link = "Link"
    }
}

struct TemperatureDaily: Codable {
    let minimum: Value
    let maximum: Value

    enum CodingKeys: String, CodingKey {
        case minimum = "Minimum"
        case maximum = "Maximum"
    }
}

struct Value: Codable {
    let value: Double
    let unit: String
    let unitType: Int

    enum CodingKeys: String, CodingKey {
        case value = "Value"
        case unit = "Unit"
        case unitType = "UnitType"
    }
}

struct Day: Codable {
    let icon: Int
    let iconPhrase: String
    let hasPrecipitation: Bool
    let precipitationType: String?
    let precipitationIntensity: String?

    enum CodingKeys: String, CodingKey {
        case icon = "Icon"
        case iconPhrase = "IconPhrase"
        case hasPrecipitation = "HasPrecipitation"
        case precipitationType = "PrecipitationType"
        case precipitationIntensity = "PrecipitationIntensity"
    }
}

struct Night: Codable {
    let icon: Int
    let iconPhrase: String
    let hasPrecipitation: Bool
    let precipitationType: String?
    let precipitationIntensity: String?

    enum CodingKeys: String, CodingKey {
        case icon = "Icon"
        case iconPhrase = "IconPhrase"
        case hasPrecipitation = "HasPrecipitation"
        case precipitationType = "PrecipitationType"
        case precipitationIntensity = "PrecipitationIntensity"
    }
}
