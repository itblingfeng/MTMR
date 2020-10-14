
//
//  CurrencyBarItem.swift
//  MTMR
//
//  Created by Daniel Apatin on 18.04.2018.
//  Copyright © 2018 Anton Palgunov. All rights reserved.
//

import Cocoa
import CoreLocation



class GpBarItem: CustomButtonTouchBarItem {
    private let activity: NSBackgroundActivityScheduler
    private var code: String
    private var decimalValue: Float32!
    private var decimalString: String!
    private var oldValue: Float32!


    init(identifier: NSTouchBarItem.Identifier, interval: TimeInterval, code: String) {
        activity = NSBackgroundActivityScheduler(identifier: "\(identifier.rawValue).updatecheck")
        activity.interval = interval
        self.code = code
        
        super.init(identifier: identifier, title: "⏳")

        activity.repeats = true
        activity.qualityOfService = .utility
        activity.schedule { (completion: NSBackgroundActivityScheduler.CompletionHandler) in
            self.updateGp()
            completion(NSBackgroundActivityScheduler.Result.finished)
        }
        updateGp()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func updateGp() {
        let urlRequest = URLRequest(url: URL(string: "http://152.136.59.80:8080/list?code=\(code)")!)
        let task = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
           if error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: AnyObject]
                    let name:String = json["name"] as!String
                    let price: String = json["price"] as!String
                    DispatchQueue.main.async {
                        self.setGp(value: Float32(price)!, name: name)
                    }
                } catch let jsonError {
                    print(jsonError.localizedDescription)
                }
            }
       }

       task.resume()
    }

    func setGp(value: Float32, name: String) {
        var color = NSColor.white

        if let oldValue = self.oldValue {
            if oldValue < value {
                color = NSColor.green
            } else if oldValue > value {
                color = NSColor.red
            }
        }

        oldValue = value
        decimalString = String(oldValue)

        let title = name + ":" + String(decimalString)

        let regularFont = attributedTitle.attribute(.font, at: 0, effectiveRange: nil) as? NSFont ?? NSFont.systemFont(ofSize: 15)
        let newTitle = NSMutableAttributedString(string: title as String, attributes: [.foregroundColor: color, .font: regularFont, .baselineOffset: 1])
        newTitle.setAlignment(.center, range: NSRange(location: 0, length: title.count))
        attributedTitle = newTitle
    }

    
    deinit {
        activity.invalidate()
    }
}
