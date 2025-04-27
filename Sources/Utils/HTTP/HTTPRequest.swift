import Foundation

struct HTTPRequest {
  var url: URL
  var method: HTTPMethod
  var headers: [String: String]?
  var query: [String: String]?
  var body: Data?

  init(
    url: URL,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    query: [String: String]? = nil,
    body: Data? = nil
  ) {
    self.url = url
    self.method = method
    self.headers = headers
    self.query = query
    self.body = body
  }
}
