//
//  UIViewController+Extension.swift
//  VirtualTourist
//
//  Created by Fatimah on 02/05/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import UIKit
extension UIViewController {
    
    func showFailure(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(dismissAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
