//
//  ViewController.swift
//  GoogleAdsDemonstration
//
//  Created by IPH Technologies Pvt. Ltd. on 30/11/23.
//

import UIKit
import GoogleMobileAds
import UserMessagingPlatform

class BannerViewController: UIViewController {
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var consentRevokeButton: UIButton!
    
    // Use a boolean to initialize the Google Mobile Ads SDK and load ads once.
    private var isMobileAdsStartCalled = false
    //added for consent revokation
    var isPrivacyOptionsRequired: Bool {
        return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.delegate = self
        GDPRConsentForm()
    }
    
    @IBAction func consentRevokeAction(_ sender: UIButton) {
        UMPConsentForm.presentPrivacyOptionsForm(from: self) {
            [weak self] formError in
            guard let self, let formError else { return }
            // Handle the error.
        }
    }
    
    @IBAction func interstitialAdAction(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "InterstitialAdViewController") as! InterstitialAdViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func GDPRConsentForm() {
        // Create a UMPRequestParameters object.
        let parameters = UMPRequestParameters()
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        parameters.debugSettings = debugSettings
        // Set tag for under age of consent. false means users are not under age
        // of consent.
        parameters.tagForUnderAgeOfConsent = false
        //for resetting the request everytime the view loads.
        UMPConsentInformation.sharedInstance.reset()
        // Request an update for the consent information.
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) {
            [weak self] requestConsentError in
            guard let self else { return }
            if let consentError = requestConsentError {
                // Consent gathering failed.
                return print("Error: \(consentError.localizedDescription)")
            }
            // Load and present the consent form.
            UMPConsentForm.loadAndPresentIfRequired(from: self) {
                [weak self] loadAndPresentError in
                guard let self else { return }
                
                if let consentError = loadAndPresentError {
                    // Consent gathering failed.
                    return print("Error: \(consentError.localizedDescription)")
                }
                // Consent has been gathered.
                if UMPConsentInformation.sharedInstance.canRequestAds {
                    self.startGoogleMobileAdsSDK()
                }
                // Show the button if privacy options are required.
                self.consentRevokeButton.isEnabled = self.isPrivacyOptionsRequired
            }
        }
        // Check if you can initialize the Google Mobile Ads SDK in parallel
        // while checking for new consent information. Consent obtained in
        // the previous session can be used to request ads.
        if UMPConsentInformation.sharedInstance.canRequestAds {
            startGoogleMobileAdsSDK()
        }
    }
    
    private func startGoogleMobileAdsSDK() {
        DispatchQueue.main.async {
            guard !self.isMobileAdsStartCalled else { return }
            
            self.isMobileAdsStartCalled = true
            
            // Initialize the Google Mobile Ads SDK.
            GADMobileAds.sharedInstance().start()
            
            // Request an ad.
            self.bannerView.load(GADRequest())
        }
    }
}

extension BannerViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("bannerViewDidReceiveAd")
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillPresentScreen")
    }
    
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillDIsmissScreen")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewDidDismissScreen")
    }
}
