struct HTTPResponse<T> {
  let data: T
  let statusCode: Int
  let headers: [AnyHashable: Any]
}
