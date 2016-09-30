import HTTPServer

let responder = BasicResponder({ _ in Response() })
let server = try Server(port: 8111, responder: responder)
try server.start()
