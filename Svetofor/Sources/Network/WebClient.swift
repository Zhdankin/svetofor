//
//  WebClient.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 02.03.2022.
//

import Foundation

class WebAPIClient {
    
    static let shared = WebAPIClient()
    
    let session: URLSession

    var webAPIURL: URL {
        return URL(string: "http://138.201.214.73:8080/external")!
    }
    
    init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }
    
    func requestCheckCarNumber(carNumber: String, completion: @escaping (Result<CarNumberCheckDataResponse, VerifyCarNumberError>) -> Void) {
        let url = self.webAPIURL
            .appendingPathComponent("external")
            .appendingPathComponent("car")

        var urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "car_plate", value: carNumber)]
        
        
        urlComponents?.url.map {
            self.session.dataTask(with: $0) { data, response, error in
                if let `error` =  error {
                    completion(Result.failure(VerifyCarNumberError.other(error)))
                }
                else if let jsonData = data {
                    do {
                        let carNumberResponse = try JSONDecoder().decode(CarNumberCheckDataResponse.self, from: jsonData)
                        DispatchQueue.main.async {
                            completion(Result.success(carNumberResponse))
                        }
                    }
                    catch {
                        do {
                            let carNumberErrorResponse = try JSONDecoder().decode(CarNumberCheckDataErrorResponse.self, from: jsonData)
                            DispatchQueue.main.async {
                                completion(Result.failure(VerifyCarNumberError.logicError(carNumberErrorResponse.code, carNumberErrorResponse.message)))
                            }
                        }
                        catch {
                            DispatchQueue.main.async {
                                completion(Result.failure(VerifyCarNumberError.jsonError(error)))
                            }
                        }
                    }
                }
            }
        }?.resume()
    }
}
