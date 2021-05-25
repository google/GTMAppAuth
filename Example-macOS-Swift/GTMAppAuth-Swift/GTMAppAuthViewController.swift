//
//  GTMAppAuthViewController.swift
//  GTMAppAuth-Swift
//
//  Created by Grant K2 on 21/02/2018.
//  Copyright © 2018 Google. All rights reserved.
//
import Foundation
import Cocoa
import GTMAppAuth
import AppAuth
import QuartzCore
import GTMSessionFetcher

class GTMAppAuthViewController: NSViewController, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    var appDel: AppDelegate = (NSApplication.shared.delegate as? AppDelegate)!
    
    var authorization: GTMAppAuthFetcherAuthorization?
    
    // NOTE:
    // To run this sample, you need to register your own Google API client at
    // https://console.developers.google.com/apis/credentials?project=_ and update three configuration
    // points in the sample: kClientID and kRedirectURI constants in AppAuthExampleViewController.m
    // and the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0).
    // Full instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example-Mac/README.md
    //TODO: Fix incorrect link to doc from original project
    
    // 1. Obtain details from here: https://console.developers.google.com
    let kIssuer: String = "https://accounts.google.com" //TODO: Adopt String code style when done porting.
    let kClientID: String = "com.googleusercontent.apps.<YOUR-CLIENT-ID>" // TODO: Grab from Google generated Plist
    let kclientSecret =  "" // Client ID for IOS config in Google Apis console doesn't seem to generate a client Secret so we will leave it blank
    let kRedirectURI = "com.googleusercontent.apps.<YOUR-CLIENT-ID>:/oauthredirect" // TODO: Grab from Google Plist
    
    // 2. Make sure you have enabled Sandbox Entitlements and have allowed Outgoing connection otherwise this will not work.(Under Project-> Capabilities. This has been done in this project)
    // 3. Update the  `kRedirectURI` with the *reverse DNS notation* form of the client ID. For example, if the client ID is
    //    `YOUR_CLIENT.apps.googleusercontent.com`, the reverse DNS notation would be
    //    `com.googleusercontent.apps.YOUR_CLIENT`. A path component is added resulting in
    //    `"com.googleusercontent.apps.<YOUR-CLIENT-ID>:/oauthredirect"`.
    // 4. If you want to access a specific service then update the scopes below. We have added in Scope to get ID and Profile data for the purpose of this demo. For additional Google scopes, you can get these from the Google scopes URL: https://developers.google.com/identity/protocols/googlescopes
    let scopesToAccess = [OIDScopeOpenID, OIDScopeProfile]
    
    let kExampleAuthorizeKey = "authState"
    
    @IBAction func authWithAutoCodeExchange(_ sender: NSButton) {
        
        guard let issuer = URL(string: kIssuer) else {
            self.logMessage("Error creating URL for : \(kIssuer)")
            return
        }
        self.logMessage("Fetching configuration for issuer: \(issuer)")
        let redirectURI = URL(string: kRedirectURI)!
        
        //discovers endpoints
        //TODO: Make it clearer in doc how to do the various methods to get config.  Will do it manually for now as its simple and easy.
        // Manually get Endpoints
        let config = GTMAppAuthFetcherAuthorization.configurationForGoogle()
        print(config)
        self.logMessage("Got configuration:\(config)")
        
        // builds authentication request
        let request: OIDAuthorizationRequest = OIDAuthorizationRequest(configuration: config, clientId: self.kClientID, clientSecret: self.kclientSecret, scopes: scopesToAccess, redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
        
        // performs authentication request
        self.appDel.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, callback: { (authState, error) in
            
            if let authState = authState  {
                let authorizationLocal = GTMAppAuthFetcherAuthorization(authState: authState)
                self.setAuthorization(authorizationLocal)
                self.logMessage("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken)")
            } else {
                if let error = error {
                    self.setAuthorization(nil)
                    self.logMessage("Authorization error: \(error.localizedDescription)")
                }
            }
        })
    }
    @IBAction func userinfo(_ sender: NSButton) {
        self.logMessage("Performing User Info Request")
        
        // Creates a GTMSessionFetcherService with the authorization.
        // Normally you would save this service object and re-use it for all REST API calls.
        let fetcherService = GTMSessionFetcherService()
        fetcherService.authorizer = self.authorization
        
        // Creates a fetcher for the API call.
        let userinfoEndpoint = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
        let fetcher = fetcherService.fetcher(with: userinfoEndpoint)
        fetcher.beginFetch { (data, error) in
            // Checks for an error.
            if let error = error {
                print(error.localizedDescription)
                self.logMessage("error:\(error.localizedDescription)")
                // OIDOAuthTokenErrorDomain indicates an issue with the authorization.
                //TODO: Error doesn't have a domain
                //                if error. == OIDOAuthTokenErrorDomain {
                //                    self.setAuthorization(nil)
                //                    self.logMessage("Authorization error during token refresh, clearing state. \(error)")
                //                } else {
                //                self.logMessage("Transient error during token refresh. \(error)")
                //            }
            }
            //JSON Error
            
            do {
                let jsonDictORArray = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                // Sucess Response:
                self.logMessage("Success \(jsonDictORArray)")
            } catch (let parsingError){
                print("JSON decoding error: \(parsingError)")
                return
            }
            
        }
    }
    
    @IBAction func forceRefresh(_ sender: NSButton) {
        authorization?.authState.setNeedsTokenRefresh()
    }
    
    @IBAction func clearAuthState(_ sender: NSButton) {
        self.authorization = nil
    }
    
    @IBAction func clearLog(_ sender: NSButton) {
        //logTextView.textStorage = NSTextStorage(string: "") // This is get only so can't use the method in other docs
        logTextView.string = ""
    }
    
    @IBOutlet var logTextView: NSTextView!
    @IBOutlet weak var authAutoButton: NSButton!
    @IBOutlet weak var userInfoButton: NSButton!
    @IBOutlet weak var forceRefreshButton: NSButton!
    @IBOutlet weak var clearAuthStateButton: NSButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(kIssuer != "https://issuer.example.com",
               "Update kIssuer with your own issuer.\n" +
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        
        assert(kClientID != "YOUR_CLIENT_ID",
               "Update kClientID with your own client ID.\n" +
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        
        assert(kRedirectURI != "com.example.app:/oauth2redirect/example-provider",
               "Update kRedirectURI with your own redirect URI.\n" +
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        
        // verifies that the custom URI scheme has been updated in the Info.plist
        guard let urlTypes: [AnyObject] = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject], urlTypes.count > 0 else {
            assertionFailure("No custom URI scheme has been configured for the project.")
            return
        }
        
        guard let items = urlTypes[0] as? [String: AnyObject],
            let urlSchemes = items["CFBundleURLSchemes"] as? [AnyObject], urlSchemes.count > 0 else {
                assertionFailure("No custom URI scheme has been configured for the project.")
                return
        }
        
        guard let urlScheme = urlSchemes[0] as? String else {
            assertionFailure("No custom URI scheme has been configured for the project.")
            return
        }
        self.loadState()
        self.updateUI()
    }
    func saveState() {
        if authorization!.canAuthorize() {
            GTMAppAuthFetcherAuthorization.save(authorization!, toKeychainForName: kExampleAuthorizeKey)
        } else {
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: kExampleAuthorizeKey)
        }
    }
    func loadState() {
        if let authorization =  GTMAppAuthFetcherAuthorization(fromKeychainForName: kExampleAuthorizeKey) {
            self.setAuthorization(authorization)
        }
    }
    
    func updateUI() {
        guard authorization != nil
            else{
                self.authAutoButton.title = "Authorize"
                return
        }
        userInfoButton.isEnabled = (authorization?.canAuthorize())!
        forceRefreshButton.isEnabled = (authorization?.canAuthorize())!
        clearAuthStateButton.isEnabled = authorization != nil
        
        // dynamically changes authorize button text depending on authorized state
        if authorization != nil {
            authAutoButton.title = "Authorize"
        } else {
            authAutoButton.title = "Re-authorize"
        }
    }
    
    func stateChanged()  {
        self.saveState()
        self.updateUI()
    }
    
    func didChangeState(state: OIDAuthState) {
        self.stateChanged()
    }
    
    
    //MARK: Protocol Methods
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        self.logMessage("Received authorization error \(error)")
    }
    
    
    func didChange(_ state: OIDAuthState) {
        // TODO(referenced wdenniss): update for GTMAppAuth
        self.stateChanged()
    }
    
    
    func logMessage(_ message: String) {
        //TODO: Clarify objective of this...
        //        // gets message as string
        //        va_list argp;
        //        va_start(argp, format);
        //        NSString *log = [[NSString alloc] initWithFormat:format arguments:argp];
        //        va_end(argp);
        
        // outputs to stdout
        NSLog("%@", message)
        
        // appends to output log
        //TODO: If we are using STD out above we probably want to format the list.
        // appends to output log
        //        let dataFormatter = DateFormatter()
        //        dataFormatter.dateFormat = "hh:mm:ss"
        
        let logLineAttr = NSAttributedString(string: message)
        logTextView.textStorage?.append(logLineAttr)
    }
    func setAuthorization(_ authorization: GTMAppAuthFetcherAuthorization?) {
        self.authorization = authorization
        self.saveState()
        self.updateUI()
    }
    
}
