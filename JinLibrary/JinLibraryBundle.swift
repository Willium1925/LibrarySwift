//
//  JinLibraryBundle.swift
//  JinLibrary
//
//  Created by fcuiecs on 2025/10/14.
//

import WidgetKit
import SwiftUI

@main
struct JinLibraryBundle: WidgetBundle {
    var body: some Widget {
        JinLibrary()
        JinLibraryControl()
        JinLibraryLiveActivity()
        BookCarouselWidget()
    }
}
