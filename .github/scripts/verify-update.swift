import Foundation
import CryptoKit
func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}
let args = CommandLine.arguments
guard args.count == 4 else { fail("Usage: verify-update Info.plist archive signature") }
let plistData = try Data(contentsOf: URL(fileURLWithPath: args[1]))
let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as! [String: Any]
guard let encoded = plist["SUPublicEDKey"] as? String, let raw = Data(base64Encoded: encoded), let signature = Data(base64Encoded: args[3]) else { fail("Invalid public key or signature") }
let key = try Curve25519.Signing.PublicKey(rawRepresentation: raw)
let archive = try Data(contentsOf: URL(fileURLWithPath: args[2]))
guard key.isValidSignature(signature, for: archive) else { fail("Update signature does not match installed public key") }
print("PASS: update archive signature matches installed Sparkle public key")
