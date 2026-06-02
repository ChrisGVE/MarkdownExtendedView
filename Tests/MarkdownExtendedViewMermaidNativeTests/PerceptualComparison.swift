// PerceptualComparison.swift
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

import CoreGraphics
import Foundation
import ImageIO

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Perceptual PNG comparison with a tolerance robust to anti-aliasing / font
/// micro-diffs (PRD D5 / T6). Decoding uses ImageIO/CoreGraphics (portable
/// across iOS + macOS). The comparison combines luminance SSIM (windowed) with
/// a per-pixel channel-delta ratio.
enum PerceptualComparison {

    /// SSIM at or above this is a pass.
    static let ssimThreshold: Double = 0.98
    /// At most this fraction of pixels may differ beyond `maxChannelDelta`.
    static let maxDifferentPixelRatio: Double = 0.005
    /// A channel delta (0…255) at or below this is "the same pixel".
    static let maxChannelDelta: Int = 8

    enum Result {
        case pass(ssim: Double, differentPixelRatio: Double)
        case fail(reason: String, ssim: Double, differentPixelRatio: Double)

        var passed: Bool { if case .pass = self { return true } else { return false } }
        var describe: String {
            switch self {
            case let .pass(ssim, ratio): return "pass (ssim=\(ssim), diff=\(ratio))"
            case let .fail(reason, ssim, ratio): return "FAIL \(reason) (ssim=\(ssim), diff=\(ratio))"
            }
        }
    }

    struct Bitmap {
        let width: Int
        let height: Int
        let rgba: [UInt8] // width*height*4, premultiplied last
    }

    /// Decode PNG bytes to an RGBA8 bitmap, or nil if undecodable.
    static func decode(_ png: Data) -> Bitmap? {
        guard let source = CGImageSourceCreateWithData(png as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        let width = image.width, height = image.height
        guard width > 0, height > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = buffer.withUnsafeMutableBytes({ raw -> CGContext? in
            CGContext(
                data: raw.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: colorSpace, bitmapInfo: bitmapInfo
            )
        }) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Bitmap(width: width, height: height, rgba: buffer)
    }

    /// Compare a candidate PNG against a reference PNG.
    static func compare(candidate: Data, reference: Data) -> Result {
        guard let a = decode(candidate), let b = decode(reference) else {
            return .fail(reason: "undecodable PNG", ssim: 0, differentPixelRatio: 1)
        }
        guard a.width == b.width, a.height == b.height else {
            return .fail(
                reason: "dimension mismatch \(a.width)x\(a.height) vs \(b.width)x\(b.height)",
                ssim: 0, differentPixelRatio: 1
            )
        }
        let diffRatio = differentPixelRatio(a, b)
        let ssim = luminanceSSIM(a, b)
        if ssim >= ssimThreshold, diffRatio <= maxDifferentPixelRatio {
            return .pass(ssim: ssim, differentPixelRatio: diffRatio)
        }
        return .fail(reason: "below tolerance", ssim: ssim, differentPixelRatio: diffRatio)
    }

    // MARK: - Metrics

    private static func differentPixelRatio(_ a: Bitmap, _ b: Bitmap) -> Double {
        let count = a.width * a.height
        guard count > 0 else { return 0 }
        var differing = 0
        var i = 0
        while i < a.rgba.count {
            let dr = abs(Int(a.rgba[i]) - Int(b.rgba[i]))
            let dg = abs(Int(a.rgba[i + 1]) - Int(b.rgba[i + 1]))
            let db = abs(Int(a.rgba[i + 2]) - Int(b.rgba[i + 2]))
            let da = abs(Int(a.rgba[i + 3]) - Int(b.rgba[i + 3]))
            if max(max(dr, dg), max(db, da)) > maxChannelDelta { differing += 1 }
            i += 4
        }
        return Double(differing) / Double(count)
    }

    /// Windowed luminance SSIM (8×8 non-overlapping windows, averaged).
    private static func luminanceSSIM(_ a: Bitmap, _ b: Bitmap) -> Double {
        let lumA = luminance(a), lumB = luminance(b)
        let w = a.width, h = a.height
        let win = 8
        let c1 = 6.5025, c2 = 58.5225 // (0.01*255)^2, (0.03*255)^2
        var total = 0.0
        var windows = 0
        var y = 0
        while y < h {
            var x = 0
            while x < w {
                let (ma, mb, va, vb, cov, n) = windowStats(lumA, lumB, w, h, x, y, win)
                if n > 0 {
                    let ssim = ((2 * ma * mb + c1) * (2 * cov + c2))
                        / ((ma * ma + mb * mb + c1) * (va + vb + c2))
                    total += ssim
                    windows += 1
                }
                x += win
            }
            y += win
        }
        return windows > 0 ? total / Double(windows) : 1.0
    }

    private static func luminance(_ bmp: Bitmap) -> [Double] {
        var out = [Double](repeating: 0, count: bmp.width * bmp.height)
        var i = 0, p = 0
        while i < bmp.rgba.count {
            // Rec. 601 luma on premultiplied-last RGBA.
            out[p] = 0.299 * Double(bmp.rgba[i]) + 0.587 * Double(bmp.rgba[i + 1]) + 0.114 * Double(bmp.rgba[i + 2])
            i += 4
            p += 1
        }
        return out
    }

    private static func windowStats(
        _ a: [Double], _ b: [Double], _ w: Int, _ h: Int, _ x0: Int, _ y0: Int, _ win: Int
    ) -> (Double, Double, Double, Double, Double, Int) {
        var sumA = 0.0, sumB = 0.0, sumAA = 0.0, sumBB = 0.0, sumAB = 0.0
        var n = 0
        for y in y0..<min(y0 + win, h) {
            for x in x0..<min(x0 + win, w) {
                let idx = y * w + x
                let va = a[idx], vb = b[idx]
                sumA += va; sumB += vb
                sumAA += va * va; sumBB += vb * vb; sumAB += va * vb
                n += 1
            }
        }
        guard n > 0 else { return (0, 0, 0, 0, 0, 0) }
        let nD = Double(n)
        let meanA = sumA / nD, meanB = sumB / nD
        let varA = sumAA / nD - meanA * meanA
        let varB = sumBB / nD - meanB * meanB
        let cov = sumAB / nD - meanA * meanB
        return (meanA, meanB, varA, varB, cov, n)
    }
}
