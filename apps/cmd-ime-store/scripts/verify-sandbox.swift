import Foundation
import Security

let appURL = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
var code: SecStaticCode?
var information: CFDictionary?
guard SecStaticCodeCreateWithPath(appURL, [], &code) == errSecSuccess,
      let code,
      SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
      let values = information as? [String: Any],
      let entitlements = values[kSecCodeInfoEntitlementsDict as String] as? [String: Any],
      entitlements["com.apple.security.app-sandbox"] as? Bool == true
else {
    FileHandle.standardError.write(Data("App Sandbox is missing from the signature.\n".utf8))
    exit(1)
}
