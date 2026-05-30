// LaTeXView.swift
// MarkdownExtendedView
//
// Copyright 2025 Christian C. Berclaz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import ExtendedSwiftMath

/// A view that renders LaTeX equations using SwiftMath.
struct LaTeXView: View {

    let latex: String
    let isBlock: Bool
    let theme: MarkdownTheme

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isBlock {
            // Display/block math - centered, larger
            HStack {
                Spacer()
                mathView
                    .padding(.vertical, 12)
                Spacer()
            }
        } else {
            // Inline math - flows with text
            mathView
        }
    }

    @ViewBuilder
    private var mathView: some View {
        MathView(latex: latex)
            .font(fontSize: isBlock ? 20 : 16)
            .foregroundColor(textColor)
    }

    private var textColor: MTColor {
        #if os(iOS)
        return colorScheme == .dark ? .white : .black
        #elseif os(macOS)
        return colorScheme == .dark ? .white : .black
        #endif
    }
}

// MARK: - MathView (SwiftMath Wrapper)

/// A SwiftUI wrapper for SwiftMath's MTMathUILabel.
struct MathView {

    let latex: String

    fileprivate var fontSize: CGFloat = 16
    fileprivate var textColor: MTColor = .black
    fileprivate var textAlignment: MTTextAlignment = .left

    init(latex: String) {
        self.latex = latex
    }

    // MARK: - Modifiers

    func font(fontSize: CGFloat) -> MathView {
        var view = self
        view.fontSize = fontSize
        return view
    }

    func foregroundColor(_ color: MTColor) -> MathView {
        var view = self
        view.textColor = color
        return view
    }

    func textAlignment(_ alignment: MTTextAlignment) -> MathView {
        var view = self
        view.textAlignment = alignment
        return view
    }
}

#if os(iOS)
extension MathView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.latex = latex
        label.fontSize = fontSize
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.labelMode = .display
        label.backgroundColor = .clear
        return label
    }

    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = latex
        uiView.fontSize = fontSize
        uiView.textColor = textColor
        uiView.textAlignment = textAlignment
    }
}
#elseif os(macOS)
extension MathView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.latex = latex
        label.fontSize = fontSize
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.labelMode = .display
        // Note: backgroundColor not accessible on macOS, view is transparent by default
        return label
    }

    func updateNSView(_ nsView: MTMathUILabel, context: Context) {
        nsView.latex = latex
        nsView.fontSize = fontSize
        nsView.textColor = textColor
        nsView.textAlignment = textAlignment
    }
}
#endif

// MARK: - Preview

#if DEBUG
struct LaTeXView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Inline LaTeX:")
            HStack {
                Text("The formula")
                LaTeXView(latex: "E = mc^2", isBlock: false, theme: .default)
                Text("is famous.")
            }

            Divider()

            Text("Block LaTeX:")
            LaTeXView(
                latex: "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}",
                isBlock: true,
                theme: .default
            )
        }
        .padding()
    }
}
#endif
