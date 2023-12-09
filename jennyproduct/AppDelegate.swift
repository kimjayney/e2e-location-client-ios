//
//  AppDelegate.swift
//  jennyproduct
//
//  Created by jenny on 2020/07/26.
//  Copyright © 2020 jenny. All rights reserved.
//

import UIKit
import CoreLocation
import Network
import Foundation
import CommonCrypto
import CryptoSwift





extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    func base64Decoded() -> Data? {
        return Data(base64Encoded: self)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    let monitor = NWPathMonitor()
    var locationQueue : Array<Any> = []
    let userDefaults = UserDefaults.standard
   
    
    func createIV(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    
    
    func aesEncrypt(key: String, iv: String, data: String) -> String? {
        let keyData = key.data(using: .utf8)
        let ivData = iv.data(using: .utf8)
        let dataData = data.data(using: .utf8)

        do {
            let aes = try AES(key: keyData!.bytes, blockMode: CBC(iv: ivData!.bytes))
            let encryptedData = try aes.encrypt(dataData!.bytes)
            return Data(encryptedData).base64EncodedString()
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func aesDecrypt(key: String, iv: String, data: String) -> String? {
        let keyData = key.data(using: .utf8)
        let ivData = iv.data(using: .utf8)
        let dataData = Data(base64Encoded: data)

        do {
            let aes = try AES(key: keyData!.bytes, blockMode: CBC(iv: ivData!.bytes))
            let decryptedData = try aes.decrypt(dataData!.bytes)
            return String(data: Data(decryptedData), encoding: .utf8)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }


    @objc func defaultsChanged(notification: Notification) {
        let collectStatus = userDefaults.bool(forKey: "collectStatus")
        if collectStatus == true {
            print("수집 시작")
            startBackgroundTask()
        } else {
            print("현재상태")
            print(collectStatus)
            stopBackgroundTask()
        
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        print("TestDebugPrint!")
        let userDefaults = UserDefaults.standard
        let settingValue = userDefaults.bool(forKey: "collectStatus")
        let privateKey = userDefaults.string(forKey: "privateKey")
        
        let appData = AppData()
        appData.loadSetting()
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)

        if settingValue == true {
            print("Collect Start")
        } else {
            userDefaults.set(createIV(length: 32), forKey: "privateKey")
        }
        return true
    }
    
    

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        // 500, 1000 개 씩 보내면서 배터리 오래가도록 구현해야함
        // 실 api서버는 TLS1.3 로 연결되도록 보안성을 갖추어야함
        // URLSesssion이 TLS1.3지원 여부 확인해야함
        let latitude = locValue.latitude
        let longitude = locValue.longitude
        
        if userDefaults.bool(forKey: "collectStatus") == true {
            let Iv = createIV(length: 16)
            do {
//                print("locations = \(locValue.latitude) \(locValue.longitude)")
                let key = userDefaults.string(forKey: "privateKey") ?? "no_key" // if no_key, no encryption, only use device key, deviceId (unsecure)
                let encrypt_lat =  aesEncrypt(key: key, iv: Iv, data: String(latitude))
                let encrypt_long = aesEncrypt(key: key, iv: Iv, data: String(longitude))
//                print("locations = \(encrypt_lat) \(encrypt_long)")
                let decrypt_lat = aesDecrypt(key: key, iv: Iv, data: encrypt_lat ?? ".")
//                print("locationsDec= \(decrypt_lat)")
                
                let deviceId = userDefaults.string(forKey: "deviceId") ?? "nodeviceId"
                let deviceAuthorization = userDefaults.string(forKey: "deviceKey") ?? "nodeviceId"
                guard let encode_lat = encrypt_lat?.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let encode_lng = encrypt_long?.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let urlString = "https://jayneycoffee.api.location.rainclab.net/api/update?lat=\(encode_lat)&lng=\(encode_lng)&device=\(deviceId)&iv=\(Iv)&authorization=\(deviceAuthorization)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: urlString) else {
                    print("Error: failed to create URL")
                    return
                }
                print("URL")
                print(url)
                var request = URLRequest(url: url)

                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                request.addValue("csrf-token", forHTTPHeaderField: "X-CSRFToken")

                let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                    guard let data = data else { return }
                    print(String(data: data, encoding: .utf8)!)
                }

                task.resume()
            } catch {
                print("Encryption failed with error: \(error)")
            }
        } else {
            print("수집이 안되고 있어요 false라서요")
            
        }
        
    }
    
    
    
    func startBackgroundTask() {
        print("startBackgroundTask")
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.activityType = .other
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringVisits()
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    func stopUpdationgLocation() {

        self.locationManager.stopUpdatingLocation()
    }
    func stopBackgroundTask() {
        stopUpdationgLocation()
        
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting
        
        connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

