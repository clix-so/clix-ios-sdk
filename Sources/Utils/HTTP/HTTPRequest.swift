import Foundation

struct HTTPRequest {
  var url: URL
  var method: HTTPMethod = .get
  var params: [String: Any]?
  var headers: [String: String]?
  var data: Encodable?

  init(
    url: URL,
    method: HTTPMethod = .get,
    params: [String: Any]? = nil,
    headers: [String: String]? = nil,
    data: Encodable? = nil
  ) {
    self.url = url
    self.method = method
    self.params = params
    self.headers = headers
    self.data = data
  }
}
