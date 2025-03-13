import SwiftUI

struct Typography {
    static let largeTitle = Font.custom("SF Pro", size: 34).weight(.regular)
    static let largeTitleEmphasized = Font.custom("SF Pro", size: 34).weight(.black).italic()

    static let title1 = Font.custom("SF Pro", size: 28).weight(.regular)
    static let title1Emphasized = Font.custom("SF Pro", size: 28).weight(.black).italic()

    static let title2 = Font.custom("SF Pro", size: 22).weight(.regular)
    static let title2Emphasized = Font.custom("SF Pro", size: 22).weight(.black).italic()

    static let title3 = Font.custom("SF Pro", size: 20).weight(.regular)
    static let title3Emphasized = Font.custom("SF Pro", size: 20).weight(.black).italic()

    static let headline = Font.custom("SF Pro", size: 17).weight(.black).italic()

    static let body = Font.custom("SF Pro", size: 17).weight(.regular)
    static let bodyEmphasized = Font.custom("SF Pro", size: 17).weight(.semibold)

    static let callout = Font.custom("SF Pro", size: 16).weight(.regular)
    static let calloutEmphasized = Font.custom("SF Pro", size: 16).weight(.semibold)

    static let subheadline = Font.custom("SF Pro", size: 15).weight(.regular)
    static let subheadlineEmphasized = Font.custom("SF Pro", size: 15).weight(.semibold)

    static let footnote = Font.custom("SF Pro", size: 13).weight(.regular)
    static let footnoteEmphasized = Font.custom("SF Pro", size: 13).weight(.semibold)

    static let caption1 = Font.custom("SF Pro", size: 12).weight(.regular)
    static let caption1Emphasized = Font.custom("SF Pro", size: 12).weight(.medium)

    static let caption2 = Font.custom("SF Pro", size: 11).weight(.regular)
    static let caption2Emphasized = Font.custom("SF Pro", size: 11).weight(.semibold)
}
