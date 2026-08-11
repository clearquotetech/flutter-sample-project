import ClearQuoteSDK
import Flutter
import UIKit

enum ClearQuoteMethod: String {
    case initSDK
    case startInspection
    case logout
    case getDealerCode
    case isSDKInitialized
    case manualOfflineSync
}

final class ClearQuotePlugin: NSObject {
    static let methodChannelName = "com.clearquote/sdk"
    static let eventChannelName = "com.clearquote/sdk/events"
    
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    
    func register(with messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: Self.methodChannelName,
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        
        eventChannel = FlutterEventChannel(
            name: Self.eventChannelName,
            binaryMessenger: messenger
        )
        eventChannel?.setStreamHandler(self)
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = ClearQuoteMethod(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        switch method {
        case .initSDK:
            guard
                let args = call.arguments as? [String: Any],
                let key = args["key"] as? String
            else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "Missing SDK key", details: nil)
                )
                return
            }
            initSDK(key: key, result: result)
            
        case .startInspection:
            let args = call.arguments as? [String: Any] ?? [:]
            startInspection(
                clientAttrs: args["clientAttrs"] as? [String: Any],
                inputDetails: args["inputDetails"] as? [String: Any],
                userFlowParams: args["userFlowParams"] as? [String: Any],
                result: result
            )
            
        case .logout:
            ClearQuote.shared.logout()
            result(nil)
            
        case .getDealerCode:
            performOnMainThread {
                result(ClearQuote.shared.getCurrentDealerCode())
            }
            
        case .isSDKInitialized:
            performOnMainThread {
                result(ClearQuote.shared.isCQSDKInitialized())
            }

        case .manualOfflineSync:
            ClearQuote.shared.initiateOfflineInspectionsSync()
            result(nil)
        }
    }
    
    private func initSDK(key: String, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.topMostViewController() else {
                result(
                    FlutterError(code: "NO_VC", message: "No ViewController", details: nil)
                )
                return
            }
            
            ClearQuote.shared.initSDK(baseVC: rootVC, key: key) { isInitialized, code, message in
                result([
                    "isInitialized": isInitialized,
                    "code": code,
                    "message": message,
                ])
            }
        }
    }
    
    private func startInspection(
        clientAttrs: [String: Any]?,
        inputDetails: [String: Any]?,
        userFlowParams: [String: Any]?,
        result: @escaping FlutterResult
    ) {
        let attrs = Self.makeClientAttrs(from: clientAttrs)
        let details = Self.makeInputDetails(from: inputDetails)
        let flowParams = Self.makeUserFlowParams(from: userFlowParams)
        
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.topMostViewController() else {
                result(
                    FlutterError(code: "NO_VC", message: "No ViewController", details: nil)
                )
                return
            }
            
            ClearQuote.shared.startInspection(
                baseVC: rootVC,
                clearQuoteSdkDelegate: self,
                clientAttrs: attrs,
                inputDetails: details,
                userFlowParams: flowParams
            ) { started, message, code in
                result([
                    "started": started,
                    "message": message,
                    "code": code,
                ])
            }
        }
    }
    
    private static func makeClientAttrs(from dictionary: [String: Any]?) -> CQSDKClientAttrs? {
        guard let dictionary else { return nil }
        
        return CQSDKClientAttrs(
            userName: Self.stringValue(from: dictionary, key: "userName"),
            dealer: Self.stringValue(from: dictionary, key: "dealer"),
            dealerIdentifier: Self.stringValue(from: dictionary, key: "dealerIdentifier"),
            client_unique_id: Self.stringValue(from: dictionary, key: "client_unique_id"),
            organisationId: Self.stringValue(from: dictionary, key: "organisationId")
        )
    }
    
    private static func makeInputDetails(from dictionary: [String: Any]?) -> CQSDKInputDetails? {
        guard let dictionary else { return nil }
        
        let customerDict = dictionary["customerDetails"] as? [String: Any]
        let vehicleDict = dictionary["vehicleDetails"] as? [String: Any]
        let quoteDict = dictionary["quoteData"] as? [String: Any]
        
        let customerDetails: CQSDKCustomerDetails? = customerDict.map {
            CQSDKCustomerDetails(
                name: Self.stringValue(from: $0, key: "name"),
                email: Self.stringValue(from: $0, key: "email"),
                dialCode: Self.stringValue(from: $0, key: "dialCode"),
                phoneNumber: Self.stringValue(from: $0, key: "phoneNumber")
            )
        }
        
        let vehicleDetails: CQSDKVehicleDetails? = vehicleDict.map {
            CQSDKVehicleDetails(
                regNumber: Self.stringValue(from: $0, key: "regNumber"),
                make: Self.stringValue(from: $0, key: "make"),
                model: Self.stringValue(from: $0, key: "model"),
                bodyStyle: Self.stringValue(from: $0, key: "bodyStyle"),
                fuelType: Self.stringValue(from: $0, key: "fuelType"),
                variant: Self.stringValue(from: $0, key: "variant")
            )
        }
        
        let quoteData: CQSDKQuoteData? = quoteDict.map {
            CQSDKQuoteData(
                inspectionType: Self.stringValue(from: $0, key: "inspectionType"),
                fleetImageType: Self.stringValue(from: $0, key: "fleetImageType")
            )
        }
        
        return CQSDKInputDetails(
            customerDetails: customerDetails,
            vehicleDetails: vehicleDetails,
            quoteData: quoteData
        )
    }
    
    private static func makeUserFlowParams(from dictionary: [String: Any]?) -> CQSDKUserFlowParams? {
        guard let dictionary else { return nil }
        
        return CQSDKUserFlowParams(
            isOffline: Self.boolValue(from: dictionary, key: "isOffline"),
            skipInputPage: Self.boolValue(from: dictionary, key: "skipInputPage")
        )
    }
    
    private static func stringValue(from dictionary: [String: Any], key: String) -> String? {
        guard let value = dictionary[key] as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private static func boolValue(from dictionary: [String: Any], key: String) -> Bool? {
        if let value = dictionary[key] as? Bool {
            return value
        }
        if let number = dictionary[key] as? NSNumber {
            return number.boolValue
        }
        return nil
    }
    
    private func performOnMainThread(_ work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }
}

extension ClearQuotePlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

extension ClearQuotePlugin: ClearQuoteSDKDelegate {
    func inspectionCompletionStatus(
        identifier: String,
        message: String,
        code: Int,
        isOffline: Bool,
        serverQuoteId: String?,
        serverInspectionId: String?
    ) {
        eventSink?([
            "identifier": identifier,
            "message": message,
            "code": code,
            "isOffline": isOffline,
            "serverQuoteId": serverQuoteId as Any,
            "serverInspectionId": serverInspectionId as Any,
        ])
    }
}

extension UIApplication {
    func topMostViewController(
        base: UIViewController? = {
            UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        }()
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        
        return base
    }
}
