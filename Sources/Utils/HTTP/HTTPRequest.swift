import Foundation

struct HTTPRequest {
  var url: URL
  var method: HTTPMethod = .get
  var params: [String: Any]?
  var headers: [String: String]?
  var data: Encodable?
}
