// middleware/logger.gleam
// HTTP request logging middleware

import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/string
import mist.{type Connection, type ResponseData}

/// Middleware for logging HTTP requests
/// Logs: METHOD path status duration_ms
pub fn log_request(
  request: Request(Connection),
  handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  let start_time = system_time(Millisecond)

  let response = handler()

  let end_time = system_time(Millisecond)
  let duration = end_time - start_time

  let method = method_to_string(request.method)
  let path = request.path
  let status = response.status

  // Output to stderr for logs (as most servers do)
  log_request_line(method, path, status, duration)

  response
}

fn method_to_string(method: http.Method) -> String {
  case method {
    http.Get -> "GET"
    http.Post -> "POST"
    http.Put -> "PUT"
    http.Delete -> "DELETE"
    http.Patch -> "PATCH"
    http.Head -> "HEAD"
    http.Options -> "OPTIONS"
    http.Trace -> "TRACE"
    http.Connect -> "CONNECT"
    http.Other(method_str) -> string.uppercase(method_str)
  }
}

fn log_request_line(
  method: String,
  path: String,
  status: Int,
  duration: Int,
) -> Nil {
  let duration_str = case duration {
    d if d < 10 -> "0" <> int.to_string(d) <> "ms"
    d -> int.to_string(d) <> "ms"
  }

  // Format: METHOD /path STATUS duration
  let log_line =
    method <> " " <> path <> " " <> int.to_string(status) <> " " <> duration_str

  // Output to stderr using Erlang io:format
  log_message(log_line)
}

@external(erlang, "io", "format")
fn log_format(format: String, args: List(a)) -> Nil

fn log_message(message: String) -> Nil {
  log_format("~ts~n", [message])
}

// Получение текущего времени в миллисекундах
@external(erlang, "erlang", "system_time")
fn system_time(unit: TimeUnit) -> Int

type TimeUnit {
  Millisecond
}
