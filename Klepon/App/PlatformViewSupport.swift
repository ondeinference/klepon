import SwiftUI

extension ToolbarItemPlacement {
    static var kleponPrimaryAction: ToolbarItemPlacement {
        #if os(macOS)
            return .primaryAction
        #else
            return .topBarTrailing
        #endif
    }
}

extension View {
    @ViewBuilder
    func kleponInlineNavigationTitle() -> some View {
        #if os(iOS)
            self.navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }

    @ViewBuilder
    func kleponLargeNavigationTitle() -> some View {
        #if os(iOS)
            self.navigationBarTitleDisplayMode(.large)
        #else
            self
        #endif
    }

    @ViewBuilder
    func kleponOnboardingPresentation<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
            self.sheet(isPresented: isPresented, content: content)
        #else
            self.fullScreenCover(isPresented: isPresented, content: content)
        #endif
    }
}
