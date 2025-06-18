//
//  FontExtension.swift
//  C4 Playground
//
//  Created by Savio Enoson on 18/06/25.
//

import SwiftUI

let customFontName = "Jersey 10"

extension Font {
    static let cLargeTitle = Font.custom(customFontName, size: 38)
    static let cTitle = Font.custom(customFontName, size: 31)
    static let cTitle2 = Font.custom(customFontName, size: 24)
    static let cTitle3 = Font.custom(customFontName, size: 22)
    static let cBody = Font.custom(customFontName, size: 19)
    static let cSubheadline = Font.custom(customFontName, size: 16)
    static let cCaption = Font.custom(customFontName, size: 13)
}
