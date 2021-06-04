import UIKit

public struct EnvironmentManager {

	public enum Environment: String {
		case unknown
		case development
		case production

		var configFilename: String? {
			switch self {
			case .development:
				return "Config-Dev"
			case .production:
				return "Config-Prod"
			case .unknown:
				return nil
			}
		}
	}

	public static var environment: Environment = .unknown

	public static func configureEnvironment() -> Bool {
		guard let environmentString = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String else {
			fatalError("Couldn't setup the app environment. Did you forget to add an \"AppEnvironment\" key in the Info.plist?")
		}

		guard let environment = Environment(rawValue: environmentString) else {
			fatalError("Environment \"\(environmentString)\" has not been implemented yet")
		}

		EnvironmentManager.environment = environment

		return EnvironmentManager.environment != .unknown
	}

	public static var version: String {
		return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "n/a"
	}

	public static var buildNumber: Int {
		guard let buildNumberString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
			return -1
		}

		return Int((buildNumberString as NSString).intValue)
	}

}
