//
//  Theme.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit

enum Theme: Int {
    case `default`, dark

    var mainColor: UIColor {
        switch self {
        case .default:
            return UIColor(red: 47.0/255.0, green: 79.0/255.0, blue: 97.0/255.0, alpha: 1.0)
        case .dark:
            return UIColor(red: 37.0/255.0, green: 59.0/255.0, blue: 77.0/255.0, alpha: 1.0)
        }
    }

    var barStyle: UIBarStyle {
        switch self {
        case .default:
            return .default
        case .dark:
            return .black
        }
    }

    var navigationBackgroundImage: UIImage? {
        return nil
    }

}


struct ThemeManager {

    static let selectedThemeKey = "SelectedTheme"

    static func currentTheme() -> Theme {
        if let storedTheme = UserDefaults.standard.value(forKey: ThemeManager.selectedThemeKey) as? NSNumber {
            let theme = storedTheme.intValue
            return Theme(rawValue: theme)!
        } else {
            return .default
        }
    }

    static func applyTheme(theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: ThemeManager.selectedThemeKey)
        UserDefaults.standard.synchronize()

        let sharedApplication = UIApplication.shared
        sharedApplication.delegate?.window??.tintColor = theme.mainColor

        UINavigationBar.appearance().barStyle = theme.barStyle
        UINavigationBar.appearance().setBackgroundImage(theme.navigationBackgroundImage, for: .default)

        UISlider.appearance().minimumTrackTintColor = theme.mainColor

    }
}
