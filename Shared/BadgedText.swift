//
//  BadgedText.swift
//  Images
//
//  Created by Jakub Charvat on 23.11.2020.
//

import SwiftUI

struct BadgedText: View {
    init(_ mainText: String, badge badgeText: String) {
        self.mainText = mainText
        self.badgeText = badgeText
    }
    
    private let mainText: String
    private let badgeText: String
    
    fileprivate var mainTextBackgroundColor = Color.blue
    fileprivate var mainTextForegroundColor = Color.white
    fileprivate var badgeTextBackgroundColor = Color.green
    fileprivate var badgeTextForegroundColor = Color.white
    
    var body: some View {
        Text(mainText)
            .foregroundColor(mainTextForegroundColor)
            .font(.system(.title, design: .monospaced))
            .frame(width: 64, height: 64)
            .background(mainTextBackgroundColor)
            .cornerRadius(10)
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Text(badgeText)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(badgeTextForegroundColor)
                            .padding(3)
                            .background(badgeTextBackgroundColor)
                            .cornerRadius(4)
                            .offset(x: 4.0, y: -4.0)
                        Spacer()
                    }
                }
            )
            .padding([.horizontal, .top])
    }
}


//MARK: - Modifiers
extension BadgedText {
    private func changedProperty<T>(_ property: WritableKeyPath<BadgedText, T>, _ value: T) -> BadgedText {
        var new = self
        new[keyPath: property] = value
        return new
    }
    
    
    func mainBackgroundColor(_ color: Color) -> BadgedText {
        return changedProperty(\.mainTextBackgroundColor, color)
    }
    
    func mainForegroundColor(_ color: Color) -> BadgedText {
        return changedProperty(\.mainTextForegroundColor, color)
    }
    
    func badgeBackgroundColor(_ color: Color) -> BadgedText {
        return changedProperty(\.badgeTextBackgroundColor, color)
    }
    
    func badgeForegroundColor(_ color: Color) -> BadgedText {
        return changedProperty(\.badgeTextForegroundColor, color)
    }
}


//MARK: - Preview
struct BadgedText_Previews: PreviewProvider {
    static var previews: some View {
        BadgedText("10", badge: ":)")
            .mainBackgroundColor(.purple)
            .badgeBackgroundColor(.red)
    }
}
