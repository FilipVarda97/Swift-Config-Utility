# SwiftConfigUtility

**This package is used to fetch development and production configuration from backend.**

**Installation process**

To add SwiftConfigUtility package go to File -> Swift Packages -> Add Package Dependency and enter this repository URL.
Select branch -> main and you are good to go.
To see detailed Apple documentation visit this link:
https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app

**Importing SwiftConfigUtility**

What you will need to use this package:
1. Set development target to iOS 12.0 or above
2. Add two property list files (.plist) named "Config-Dev" and "Config-Prod" to your project
3. In each of the property list files add a dictionary named "backend" and add one key-value pair that has a key "baseURL" with value of type String and add the base URL as value. Keep in mind that the base URL for development and production environmenst are different.
4. In AppDelegate remember to "import SwiftConfigUtility"
5. In AppDelegate.swift add this lines of code in the "didFinishLaunchingWithOptions" function:

`ConfigurationManager.initialize(environment: .development)
BackendManager.initialize(configurationManager: ConfigurationManager.shared)`

After that you should be able to perform a request and fetch all the configuration data from the API by calling this function:

`BackendManager.shared.performRequest(type: [ConfigurationProperty].self, path: "config", method: .get) { (result) in
	switch result {
	case .success(let properties):
		// Parsing all fetched configuration data
		properties.forEach { property in
			ConfigurationManager.shared.saveConfigurationProperty(property)
		}
	case .failure(let error):
		// Called in case of an error
		print(error.localizedDescription)
	}
}`