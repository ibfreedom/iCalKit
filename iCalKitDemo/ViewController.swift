//
//  ViewController.swift
//  iCalKitDemo
//
//  Created by tramp on 2021/3/5.
//

import UIKit
import iCalKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
         guard let url = Bundle.main.url(forResource: "ATT00002", withExtension: "ics") else { return }
        do {
            let calendars = try CKSerialization.calendars(with: url)
            for calendar in calendars {
                print(calendar.text)
            }
            
            guard let value = calendars.first?.events.first?.component(for: .DESCRIPTION)?.value else { return }
            guard let event = calendars.first?.events.first else { return }
            
            print(value)
            
        } catch {
            print(error)
        }
        
//        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ics", subdirectory: nil) else { return }
//
//        for (offset, value) in urls.enumerated() where offset % 2 == 0 {
//
//            do {
//                let calendars = try CKSerialization.calendars(with: value)
//                for calendar in calendars {
//                    print("-----------------\(offset)------------------")
//                    print(calendar.text)
//                }
//            } catch {
//                print(error)
//            }
//        }
//
    }


}

