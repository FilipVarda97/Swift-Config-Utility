import Foundation

public struct ConfigurationManager {

	private let environment: EnvironmentManager.Environment

	private let plistFileName: String

	// MARK: - Singleton

	public static var _shared: ConfigurationManager?

	public static var shared: ConfigurationManager {
		guard let shared = _shared else {
			fatalError("ConfigurationManager not initialized. Please call ConfigurationManager.initialize(environment:) on app start to initialize iti before using.")
		}
		return shared
	}

	public static func initialize(environment: EnvironmentManager.Environment) {
		_shared = ConfigurationManager(environment: environment)
	}

	public init(environment: EnvironmentManager.Environment) {
		guard let configFilename = environment.configFilename else {
			fatalError("Couldn't find config filename for environment: \(environment)")
		}
		self.environment = environment
		self.plistFileName = configFilename
	}

	public func saveConfigurationProperty(_ property: ConfigurationProperty) {
		dictionary.setValue(property, forKey: property.key)
	}

	public func value<T>(type: T.Type, forKeyPath path: String) -> T? {
		return dictionary.value(forKeyPath: path) as? T
	}

	public func string(forKeyPath path: String) -> String? {
		return value(type: String.self, forKeyPath: path)
	}

	public var dictionary: NSDictionary {
		guard let path = Bundle.main.path(forResource: plistFileName, ofType: "plist"), let dictionary = NSDictionary(contentsOf: URL(fileURLWithPath: path)) else {
			fatalError("Couldn't read Config plist file!")
		}

		return dictionary
	}

}
