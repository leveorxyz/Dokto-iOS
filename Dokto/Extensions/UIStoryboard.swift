//
//  UIStoryboard.swift
//  Dokto
//
//  Created by Rupak on 10/24/21.
//

import UIKit

enum StoryboardType: String {
    case onboarding = "Onboarding"
    case dashboard = "Dashboard"
    case auth = "Auth"
    case clinicAuth = "clinicAuth"
    case pharmacyAuth = "pharmacyAuth"
}

extension UIStoryboard {
    
    static func controller(with story: StoryboardType, type: AnyClass) -> UIViewController? {
        return UIStoryboard(name: story.rawValue, bundle: nil).instantiateViewController(withIdentifier: String(describing: type))
    }
}
