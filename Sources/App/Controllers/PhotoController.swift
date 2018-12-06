import Vapor
import Foundation

final class PhotoController {
  private let photosList = ["barcelona.jpg", "oslo.jpg", "porto.jpg", "rome.jpg"]
  private let photosDirectory = "photos"
  private let fontsDirectory = "fonts"
  private let watermarkText = "ImageMagick\nVapor"
  
  func show(_ req: Request) throws -> Response {
    
    let name = try req.parameters.next(String.self)
    let filename = name.lowercased().appending(".jpg")
    
    guard photosList.contains(filename) else {
      throw Abort(.notFound, reason: "Photo not found")
    }
    
    let directory = DirectoryConfig.detect()
    let workingDirectory = URL(fileURLWithPath: directory.workDir)
    
    let file = workingDirectory.appendingPathComponent(photosDirectory, isDirectory: true).appendingPathComponent(filename)
    let font = workingDirectory.appendingPathComponent(fontsDirectory, isDirectory: true).appendingPathComponent("OpenSans-Regular.ttf")
    
    let photo = try Photo(file: file)
    let watermarkedPhoto = try photo.watermarked(with: font, and: watermarkText)
    
    return req.response(watermarkedPhoto, as: .jpeg)
  }
}
