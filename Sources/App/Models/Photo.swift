#if os(Linux)
import SwiftImageMagickLinux
#else
import SwiftImageMagickMac
#endif

import Vapor
import Foundation

/// Wrapper for photos.
final class Photo {
  private let file: URL
  
  /// Init photo object.
  /// - Parameters:
  ///     - file: URL to the photo on disk.
  init(file: URL) throws {
    
    guard FileManager.default.fileExists(atPath: file.path) else {
      throw Abort(.internalServerError, reason: "Photo file not found")
    }
    
    self.file = file
  }
  
  /// Returns watermarked image. Takes font path as input.
  /// - Parameters:
  ///     - font: URL to the font file on disk. This font will be used to create watermark text.
  ///     - text: Text that will be used as watermark on photo.
  public func watermarked(with font: URL, and text: String) throws -> Data {
    
    guard FileManager.default.fileExists(atPath: font.path) else {
      throw Abort(.internalServerError, reason: "Font file not found")
    }
    
    // Prepare magick wand stack
    MagickWandGenesis()
    
    let wand = NewMagickWand()
    let pixel = NewPixelWand()
    let draw = NewDrawingWand()
    
    // Load image into Magick Wand
    MagickReadImage(wand, file.path)
    
    // Prepare drawing wand
    PixelSetColor(pixel, "white")
    DrawSetFillColor(draw, pixel)
    DrawSetFont(draw, font.path)
    DrawSetFontSize(draw, 70)
    DrawSetGravity(draw, CenterGravity)
    DrawAnnotation(draw, 0, 0, text)
    
    // Draw watermark text
    MagickDrawImage(wand, draw)
    
    // Set image quality and type
    MagickSetImageCompressionQuality(wand, 85)
    MagickSetImageFormat(wand, "jpg")
    
    var length = 0
    
    guard let image = MagickGetImageBlob(wand, &length) else {
      throw Abort(.internalServerError, reason: "Can't get image from ImageMagick.")
    }
    
    let data = Data(bytes: image, count: length)
    
    DestroyMagickWand(wand)
    DestroyPixelWand(pixel)
    DestroyDrawingWand(draw)
    MagickRelinquishMemory(image)
    MagickWandTerminus()
    
    return data
  }
}
