import Foundation

enum HTTPError: Error {
  case invalidURL
  case network(Error)
  case server(statusCode: Int, data: Data?)
  case decoding(Error)
}
