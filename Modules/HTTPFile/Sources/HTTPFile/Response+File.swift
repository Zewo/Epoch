//extension Response {
//    public init(status: Status = .ok, headers: Headers = [:], filePath: String) throws {
//        do {
//            var filePath = filePath
//            let file: File
//
//            // This logic should not be here. It should be defined before calling the initializer.
//            // Also use some String extension like String.fileExtension?
//            if filePath.split(separator: ".").count == 1 {
//                filePath += ".html"
//            }
//
//            do {
//                file = try File(path: filePath, mode: .read)
//            } catch {
//                file = try File(path: filePath + "html", mode: .read)
//            }
//
//            self.init(status: status, headers: headers, body: file)
//
//            if let fileExtension = file.fileExtension, let mediaType = mediaType(forFileExtension: fileExtension) {
//                self.contentType = mediaType
//            }
//        } catch {
//            throw HTTPError.notFound
//        }
//    }
//}
