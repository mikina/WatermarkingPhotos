import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  // Photos controller
  let photoController = PhotoController()
  router.get("photos", "show", String.parameter, use: photoController.show)
}
