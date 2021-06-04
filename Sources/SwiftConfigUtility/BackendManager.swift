import UIKit

public struct BackendManager {

	public struct ErrorResponse: Decodable {

		enum CodingKeys: String, CodingKey {
			case error
			case errorCode = "error-code"
		}

		var error: String?
		var errorCode: Int?
	}

	public enum HttpMethod: String {
		case get
		case post
		case put
		case delete
	}

	public enum BackendError: Error {
		case couldntInitRequest
		case dataTaskError
		case notHttpResponse
		case emptyResponse
		case couldntParseResponseData(error: Error?)
		case httpError(statusCode: Int)
	}

	// MARK: - Singleton

	public static var shared: BackendManager {
		guard let shared = _shared else {
			fatalError("MiddlewareManager not initalized. Please call BackendManager.initialize(environment:) on app start to initialize it before using.")
		}
		return shared
	}

	public static var _shared: BackendManager?

	// MARK: - Private properties

	public let environment = EnvironmentManager.environment
	public let session = URLSession.shared
	public let jsonDecoder = JSONDecoder()
	public let baseUrl: URL

	// MARK: - Init

	public static func initialize(configurationManager: ConfigurationManager) {
		_shared = BackendManager(configurationManager: configurationManager)
	}

	public init(configurationManager: ConfigurationManager) {
		guard let stringUrl = configurationManager.value(type: String.self, forKeyPath: "backend.baseURL"), let url = URL(string: stringUrl) else {
			fatalError("Couldn't initialize BackendManager. Invalid baseURL!")
		}
		baseUrl = url
		if #available(iOS 12, *) {
			jsonDecoder.dateDecodingStrategy = .iso8601
		}
	}

	// MARK: - Private methods

	public func request(forPath path: String, method: HttpMethod, params: [String: Any] = [:]) -> URLRequest? {
		guard let url = URL(string: path, relativeTo: baseUrl) else {
			return nil
		}
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")

		if let jsonData = try? JSONSerialization.data(withJSONObject: params) {
			request.httpBody = jsonData
		}

		return request
	}

	// MARK: - Public methods

	public func chekcSyncDate() -> Bool {
		return false
	}

	public func performRequest<Model: Decodable>(type: Model.Type, path: String, method: HttpMethod, params: [String: Any] = [:], completion: @escaping (Result<Model, BackendError>) -> Void) {
		guard let request = request(forPath: path, method: method, params: params) else {
			DispatchQueue.main.async {
				completion(.failure(.couldntInitRequest))
			}
			return
		}

		let dataTask = session.dataTask(with: request) { (data, response, error) in
			guard error == nil else {
				DispatchQueue.main.async {
					completion(.failure(.dataTaskError))
				}
				return
			}

			guard let httpResponse = response as? HTTPURLResponse else {
				DispatchQueue.main.async {
					completion(.failure(.notHttpResponse))
				}
				return
			}

			switch httpResponse.statusCode {
			case 200...299:
				guard let data = data else {
					DispatchQueue.main.async {
						completion(.failure(.emptyResponse))
					}
					return
				}

				do {
					let model = try self.jsonDecoder.decode(Model.self, from: data)
					DispatchQueue.main.async {
						completion(.success(model))
					}
				} catch let error {
					DispatchQueue.main.async {
						completion(.failure(.couldntParseResponseData(error: error)))
					}
				}

			default:
				DispatchQueue.main.async {
					completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
				}
				return
			}
		}

		dataTask.resume()
	}

}

fileprivate extension URLRequest {

	var curlString: String {
		guard let url = url else { return "" }
		var baseCommand = #"curl "\#(url.absoluteString)""#

		if httpMethod == "HEAD" {
			baseCommand += " --head"
		}

		var command = [baseCommand]

		if let method = httpMethod, method != "GET" && method != "HEAD" {
			command.append("-X \(method)")
		}

		if let headers = allHTTPHeaderFields {
			for (key, value) in headers where key != "Cookie" {
				command.append("-H '\(key): \(value)'")
			}
		}

		if let data = httpBody, let body = String(data: data, encoding: .utf8) {
			command.append("-d '\(body)'")
		}

		return command.joined(separator: " \\\n\t")
	}

}
