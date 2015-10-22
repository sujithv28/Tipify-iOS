//
// Copyright (c) 2014 Lukhnos Liu.
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

import UIKit

struct Settings {
    static let UseDecimalPointKey = "UseDecimalPoint"

    private static let defaultBoolValues = [
        UseDecimalPointKey: true
    ]

    enum TippingRate : String {
        case Tip15Percent = "0.15"
        case Tip10Percent = "0.10"
        case Tip20Percent = "0.20"

        func toDecimal() -> Decimal {
            return Decimal(self.rawValue)
        }
    }

    static let defaultTippingRate = TippingRate.Tip15Percent

    static var tippingRate : TippingRate {
    get {
        if let rateStr = defaults.stringForKey(TippingRateKey) {
            if let rate = TippingRate(rawValue: rateStr) {
                return rate
            }
        }
        return defaultTippingRate
    }
    set {
        defaults.setValue(newValue.rawValue, forKey: TippingRateKey)
    }
    }

    static func boolForKey(key: String) -> Bool {
        if let value: Bool = defaults.valueForKey(UseDecimalPointKey) as? Bool {
            return value
        }

        if let value: Bool = defaultBoolValues[key] {
            return value
        }

        return false
    }

    static func setBool(value: Bool, forKey key: String) {
        defaults.setBool(value, forKey:key)
    }

    private static let TippingRateKey = "TippingRate"

    private static var defaults : NSUserDefaults {
        get {
            return NSUserDefaults.standardUserDefaults()
    }
    }
}
