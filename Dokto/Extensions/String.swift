//
//  String.swift
//  Dokto
//
//  Created by Rupak on 11/21/21.
//

import UIKit

extension String {
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func base64ToImage() -> UIImage? {
        if let imageData = Data.init(base64Encoded: self, options: .init(rawValue: 0)) {
            return UIImage(data: imageData)
        }
        return nil
    }
}
