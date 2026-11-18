import SwiftUI
import UIKit

// Helpers that use Liquid Glass on iOS 26 and fall back to blur on iOS 13–18.

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemThinMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = UIBlurEffect(style: style)
    }
}

struct GlassGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 16) { content }
        } else {
            content
        }
    }
}

struct ProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                Capsule().fill(Color.accentColor)
                    .frame(width: max(6, geo.size.width * CGFloat(value)))
            }
        }
        .frame(height: 6)
    }
}

extension View {
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 26, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular,
                             in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            self
                .background(BlurView().clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.5))
        }
    }

    @ViewBuilder
    func glassButton(prominent: Bool) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent).controlSize(.large)
            } else {
                self.buttonStyle(.glass).controlSize(.large)
            }
        } else {
            self
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .foregroundColor(prominent ? .white : .primary)
                .background(Group {
                    if prominent {
                        Capsule().fill(Color.accentColor)
                    } else {
                        BlurView().clipShape(Capsule())
                    }
                })
        }
    }

    @ViewBuilder
    func navTitle(_ title: String, inline: Bool = false) -> some View {
        if #available(iOS 14.0, *) {
            self.navigationTitle(title)
                .navigationBarTitleDisplayMode(inline ? .inline : .large)
        } else {
            self.navigationBarTitle(Text(title), displayMode: inline ? .inline : .large)
        }
    }

    @ViewBuilder
    func navButtons<L: View, T: View>(leading: L, trailing: T) -> some View {
        if #available(iOS 14.0, *) {
            self.toolbar {
                ToolbarItem(placement: .navigationBarLeading) { leading }
                ToolbarItem(placement: .navigationBarTrailing) { trailing }
            }
        } else {
            self.navigationBarItems(leading: leading, trailing: trailing)
        }
    }

    @ViewBuilder
    func clearListBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden).background(Backdrop())
        } else {
            self
        }
    }

    @ViewBuilder
    func sheetDetents() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.medium, .large])
        } else {
            self
        }
    }

    func fullBleed() -> some View {
        edgesIgnoringSafeArea(.all)
    }
}
