//
//  ContentView.swift
//  jennyproduct
//
//  Created by jenny on 2020/07/26.
//  Copyright © 2020 jenny. All rights reserved.
//

import SwiftUI

class AppData: ObservableObject {
    let userDefaults = UserDefaults.standard
    
    @Published var deviceId: String = ""
    @Published var deviceKey: String = ""
    @Published var privateKey: String = ""
    @Published var collectStatus: Bool = false
    @Published var deviceStatus: Bool = false
    

    init() {
        // UserDefaults 설정 가져오기
        
        deviceId = userDefaults.string(forKey: "deviceId") ?? ""
        deviceKey = userDefaults.string(forKey: "deviceKey") ?? ""
        privateKey = userDefaults.string(forKey: "privateKey") ?? ""
        collectStatus = userDefaults.bool(forKey: "collectStatus")
        deviceStatus = userDefaults.bool(forKey: "deviceStatus")
    }
    func loadSetting() {
        deviceId = userDefaults.string(forKey: "deviceId") ?? ""
        deviceKey = userDefaults.string(forKey: "deviceKey") ?? ""
        privateKey = userDefaults.string(forKey: "privateKey") ?? ""
        collectStatus = userDefaults.bool(forKey: "collectStatus")
        deviceStatus = userDefaults.bool(forKey: "deviceStatus")
    }
    

    func saveSetting() {
        // UserDefaults 설정 저장
        userDefaults.set(deviceId, forKey: "deviceId")
        userDefaults.set(deviceKey, forKey: "deviceKey")
        userDefaults.set(privateKey, forKey: "privateKey")
        userDefaults.set(collectStatus, forKey: "collectStatus")
        userDefaults.set(deviceStatus, forKey: "deviceStatus")
    }
}
 

struct RegistrationResponse: Codable {
    let success: Bool
    let status: Bool
    let messageEn: String
    let messageKo: String
    
    enum CodingKeys: String, CodingKey {
        case success, status
        case messageEn = "message_en_US"
        case messageKo = "message_ko_KR"
    }
    
    
}

 
struct ContentView: View {

    @State var deviceId: String = UserDefaults.standard.string(forKey: "deviceId") ?? ""
    @State var deviceKey: String = UserDefaults.standard.string(forKey: "deviceKey") ?? ""
    @State var privateKey: String = UserDefaults.standard.string(forKey: "privateKey") ?? ""
    @State var collectStatus: Bool = UserDefaults.standard.bool(forKey: "collectStatus")
    @State var deviceStatus: Bool = UserDefaults.standard.bool(forKey: "deviceStatus")
    @EnvironmentObject var appData: AppData
    var body: some View {
             
            VStack {
                
                // TextField에 userData를 적용하고, 사용자가 값을 변경하면 userData에 할당합니다.
                TextField("디바이스 아이디 입력", text: $appData.deviceId)
                    .padding()
                TextField("디바이스 키 입력(숫자나 영문자 12자리)", text: $appData.deviceKey)
                    .padding()
                TextField("복호화키 (서버에 전송안됨)", text: $appData.privateKey)
                    .padding()
                
                // 사용자 데이터를 UserDefaults에 저장합니다.
                Button("기기 등록하기") {
                    if deviceStatus == false {
                        guard let device = $appData.deviceId.wrappedValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
                            // deviceId가 nil일 때 처리할 작업
                            return
                        }
                        guard let authorization = $appData.deviceKey.wrappedValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
                            // deviceId가 nil일 때 처리할 작업
                            return
                        }
                        
                        print(device)
                        print(authorization)
                        guard let urlString = "https://jayneycoffee.api.location.rainclab.net/api/device/register?device=\(device)&authorization=\(authorization)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                              let url = URL(string: urlString) else {
                            print("Error: failed to create URL")
                            return
                        }

                        var request = URLRequest(url: url)

                        request.httpMethod = "GET"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                        request.addValue("csrf-token", forHTTPHeaderField: "X-CSRFToken")

                        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                            guard let data = data else { return }
                            do {
                                let decoder = JSONDecoder()
                                let registrationResponse = try decoder.decode(RegistrationResponse.self, from: data)
                                if registrationResponse.status {
                                    
                                    print("OK")
                                    print(String(data: data, encoding: .utf8)!)
                                    deviceStatus = true
                                    UserDefaults.standard.set(true, forKey: "deviceStatus")
                                    UserDefaults.standard.set($appData.deviceId.wrappedValue, forKey: "deviceId")
                                    UserDefaults.standard.set($appData.deviceKey.wrappedValue, forKey: "deviceKey")
                                } else {
                                    print("NO")
                                    print(registrationResponse)
                                    
                                    deviceStatus = false
                                    UserDefaults.standard.set(false, forKey: "deviceStatus")
                                    
                                    
                                }
                            } catch {
                                
                            }
                        }
                        task.resume()
                    } else {
                        let alert = UIAlertController(title: "알림", message: "이미 등록된 기기입니다. 초기화 후 해주세요.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "확인", style: .default))
                            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                    
                    
//                    appData.saveSetting()
                    
                    
//                    let alert = UIAlertController(title: "저장 완료", message: "설정이 저장되었습니다. ", preferredStyle: .alert)
//                        alert.addAction(UIAlertAction(title: "확인", style: .default))
//                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                }
                .padding()
                Button("위치 기록 시작") {
                    if deviceStatus == false {
                        let alert = UIAlertController(title: "알림", message: "기기 등록을 먼저 해주세요.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "확인", style: .default))
                            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                    } else {
                        if collectStatus == true {
                            let alert = UIAlertController(title: "알림", message: "이미 위치를 기록하고 있어요.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "확인", style: .default))
                                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        
                        } else {
                            collectStatus = true
                            UserDefaults.standard.set(true, forKey: "collectStatus")
                            let alert = UIAlertController(title: "알림", message: "위치 기록이 시작되었어요.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "확인", style: .default))
                                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                        
                    }
                    
                }
                .padding()
                Button("위치 기록 정지") {
                    collectStatus = false
                    UserDefaults.standard.set(false, forKey: "collectStatus")
                    let alert = UIAlertController(title: "알림", message: "위치 기록이 정지되었어요.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default))
                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                }
                .padding()
                
                Button("위치 조회하기") {
                    // 웹 브라우저 띄워서 파라미터 입력받게 하기
                    guard let url = URL(string: "https://jayneycoffee.location.rainclab.net/#locationui?deviceId=\(deviceId)&deviceKey=\(deviceKey)&privateKey=\(privateKey)"), UIApplication.shared.canOpenURL(url) else { return }

                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }.padding()
                Button("초기화하기") {
                    let alert = UIAlertController(title: "알림", message: "초기화 되었어요. 앱은 강제로 종료되어요. 다시 실행해주세요.", preferredStyle: .alert)
                    UserDefaults.standard.set(false, forKey: "collectStatus")
                    UserDefaults.standard.set(false, forKey: "deviceStatus")
                    UserDefaults.standard.set("", forKey: "deviceId")
                    UserDefaults.standard.set("", forKey: "deviceKey")
                    UserDefaults.standard.set("", forKey: "privateKey")
                    alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            exit(0)
                        }
                    })
                    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                }.padding()
                
                if collectStatus == true {
                    
                    Text("위치 기록 상태: OK")
                                    .padding()
                } else {
                    Text("위치 기록 상태: NO")
                                    .padding()
                }
                if deviceStatus == true {
                    Text("기기 등록 상태: OK")
                                    .padding()
                } else {
                    Text("기기 등록 상태: NO")
                                    .padding()
                }
                
                
                 
            }
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
