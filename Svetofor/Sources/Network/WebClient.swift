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
        return URL(string: "http://carinfo.ignisfatum.ltd/")!
    }
    
    var openDataBotwebAPIURL: URL {
        return URL(string: "https://opendatabot.com/api/")!
    }
    
    init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }
    
    func requestCheckCarNumber(carNumber: String, completion: @escaping (Result<CarNumberCheckDataResponse, VerifyCarNumberError>) -> Void) {
        let url = self.webAPIURL

        var urlComponents = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "car_plate", value: carNumber.lowercased())]
        
        
        urlComponents?.url.map {
            self.session.dataTask(with: $0) { data, response, error in
                if let `error` =  error {
                    DispatchQueue.main.async {
                        completion(Result.failure(VerifyCarNumberError.other(error)))
                    }
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
    
    
    func requestOpenDatanbotCarNumberInfo(carNumber: String, completion: @escaping (Result<OpenDataBotTranportResponse, VerifyCarNumberError>) -> Void) {
        let url = self.openDataBotwebAPIURL
            .appendingPathComponent("v3")
            .appendingPathComponent("public")
            .appendingPathComponent("transport")

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "number", value: carNumber.lowercased())]
        
        
        urlComponents?.url.map {
            self.session.dataTask(with: $0) { data, response, error in
                if let `error` =  error {
                    DispatchQueue.main.async {
                        completion(Result.failure(VerifyCarNumberError.other(error)))
                    }
                }
                else if let jsonData = data {
                    do {
                        let carNumberResponse = try JSONDecoder().decode(OpenDataBotTranportResponse.self, from: jsonData)
                        DispatchQueue.main.async {
                            completion(Result.success(carNumberResponse))
                        }
                    }
                    catch {
                        do {
                            let carNumberErrorResponse = try JSONDecoder().decode(OpenDataBotTranportErrorResponse.self, from: jsonData)
                            DispatchQueue.main.async {
                                completion(Result.failure(VerifyCarNumberError.logicError(carNumberErrorResponse.status, carNumberErrorResponse.reason)))
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
