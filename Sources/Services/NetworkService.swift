import Foundation
// HTTPClient, AnyCodable 등은 같은 타겟 내에 있으므로 import 불필요

// ClixError는 Sources/Models/ClixError.swift 에 정의된 것을 사용합니다.

// NetworkService는 이제 SDK의 HTTP 통신을 위한 유일한 진입점 역할을 합니다.
public class NetworkService {  // public으로 변경하여 외부 모듈(앱)에서 접근 가능하도록 함
  public static let shared = NetworkService()  // public으로 변경

  // httpClient는 내부 구현 상세이므로 private 유지
  private let httpClient: HTTPClient
  private var apiKey: String?
  private var endpoint: String?

  // Initializer를 internal (default)로 변경
  // 외부에서는 NetworkService.shared를 사용
  // 테스트 시에는 @testable import로 접근 가능
  init(httpClient: HTTPClient = HTTPClient()) {
    self.httpClient = httpClient
  }

  // configure 메서드는 public으로 유지
  public func configure(apiKey: String, endpoint: String) {
    self.apiKey = apiKey
    self.endpoint = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint
  }

  // 내부 헬퍼 메서드들은 private 유지
  private func makeHeaders() throws -> [String: String] {
    guard let apiKey = apiKey else {
      throw ClixError.notInitialized
    }
    return [
      "Content-Type": "application/json",
      "X-API-Key": apiKey,
    ]
  }

  private func makeURL(path: String) throws -> URL {
    guard let endpoint = endpoint,
      let url = URL(string: endpoint + path)
    else {
      throw ClixError.invalidURL
    }
    return url
  }

  private func handleRequestError(_ error: Error) -> ClixError {
    guard let httpError = error as? HTTPError else {
      // HTTPError가 아닌 다른 에러 (예: URL 생성 실패 등) 처리 개선
      if let clixError = error as? ClixError {
        return clixError  // 이미 ClixError인 경우 그대로 반환
      }
      return .networkError(error)  // 그 외는 일반 네트워크 에러로 처리
    }
    // HTTPError를 ClixError로 변환
    switch httpError {
    case .invalidURL:
      return .invalidURL  // HTTPClient 내부 오류지만 ClixError로 매핑
    case .network(let underlyingError):
      return .networkError(underlyingError)  // nil 병합 연산자 제거
    case .server(let statusCode, let data):
      // 서버 에러 로깅 등 추가 처리 가능
      print(
        "[NetworkService] Server error: \(statusCode), Data: \(String(data: data ?? Data(), encoding: .utf8) ?? "N/A")"
      )
      return .networkError(httpError)  // 상세 정보를 포함하는 ClixError 케이스 추가 고려
    case .decoding(let decError):
      return .decodingError(decError)
    }
  }

  private func encodeBody<T: Encodable>(_ body: T) throws -> Data {
    do {
      let encoder = JSONEncoder()
      // 필요한 경우 encoder 설정 추가 (e.g., dateEncodingStrategy)
      return try encoder.encode(body)
    } catch {
      throw ClixError.encodingError
    }
  }

  // --- Public API Methods ---

  // API 호출 메서드들을 public으로 선언
  public func registerDevice(token: String, userId: String?) async throws {
    let path = "/v1/devices"
    do {
      let url = try makeURL(path: path)
      let headers = try makeHeaders()

      struct RequestBody: Encodable {
        let token: String
        let platform: String = "ios"
        let userId: String?
      }
      let body = RequestBody(token: token, userId: userId)
      let bodyData = try encodeBody(body)

      struct EmptyResponse: Decodable {}
      _ = try await httpClient.post(url: url, headers: headers, body: bodyData, responseType: EmptyResponse.self)
    } catch {
      throw handleRequestError(error)  // 에러 래핑
    }
  }

  public func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    let path = "/v1/events"
    do {
      let url = try makeURL(path: path)
      let headers = try makeHeaders()

      struct RequestBody: Encodable {
        let name: String
        let properties: AnyCodable?  // AnyEncodable 사용 필요
        let userId: String?
      }
      let encodableProperties = properties.map { AnyCodable($0) }
      let body = RequestBody(name: name, properties: encodableProperties, userId: userId)
      let bodyData = try encodeBody(body)

      struct EmptyResponse: Decodable {}
      _ = try await httpClient.post(url: url, headers: headers, body: bodyData, responseType: EmptyResponse.self)
    } catch {
      throw handleRequestError(error)
    }
  }

  public func setAttribute(key: String, value: Any, userId: String?) async throws {
    let path = "/v1/user-attributes"
    do {
      let url = try makeURL(path: path)
      let headers = try makeHeaders()

      struct RequestBody: Encodable {
        let key: String
        let value: AnyCodable  // AnyEncodable 사용 필요
        let userId: String?
      }
      let body = RequestBody(key: key, value: AnyCodable(value), userId: userId)
      let bodyData = try encodeBody(body)

      struct EmptyResponse: Decodable {}
      _ = try await httpClient.post(url: url, headers: headers, body: bodyData, responseType: EmptyResponse.self)
    } catch {
      throw handleRequestError(error)
    }
  }

  // --- Download Method for Notification Service ---

  /// Notification Service Extension에서 미디어를 다운로드하기 위한 메서드
  public func downloadMedia(url: URL) async throws -> URL {
    do {
      // 내부 httpClient의 download 메서드 사용
      return try await httpClient.download(url: url)
    } catch {
      // 다운로드 실패 시 ClixError로 래핑하여 반환
      throw handleRequestError(error)
    }
  }
}
