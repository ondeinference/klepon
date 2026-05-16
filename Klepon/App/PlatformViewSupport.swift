import SwiftUI

extension ToolbarItemPlacement {
    static var kleponPrimaryAction: ToolbarItemPlacement {
        #if os(macOS)
            return .primaryAction
        #elseif os(tvOS) || os(visionOS)
            return .automatic
        #else
            return .topBarTrailing
        #endif
    }
}

extension View {
    @ViewBuilder
    func kleponReadableContentWidth() -> some View {
        #if os(iOS)
            self.frame(maxWidth: 720)
        #else
            self
        #endif
    }

    @ViewBuilder
    func kleponInteractiveButtonStyle() -> some View {
        #if os(tvOS) || os(visionOS)
            self.buttonStyle(.automatic)
        #else
            self.buttonStyle(.plain)
        #endif
    }

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
        #if os(macOS) || os(tvOS) || os(visionOS)
            self.sheet(isPresented: isPresented, content: content)
        #elseif os(iOS)
            // iPad uses a sheet so the sidebar remains visible behind the cover;
            // iPhone uses fullScreenCover for the immersive first-launch feel.
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.sheet(isPresented: isPresented, content: content)
            } else {
                self.fullScreenCover(isPresented: isPresented, content: content)
            }
        #else
            self.fullScreenCover(isPresented: isPresented, content: content)
        #endif
    }
}
