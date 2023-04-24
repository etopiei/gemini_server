import gleam/io
import gleam/bit_builder
import gleam/bit_string
import gleam/erlang/process
import gleam/erlang/file
import gleam/otp/actor
import gleam/result
import gleam/string
import glisten/acceptor
import glisten/handler
import glisten/ssl
import glisten

type ParseResult {
  ParseSuccess(result: String, remainder: String)
  ParseFailure(error: String)
}

type GeminiResponse {
  GeminiContent(data: String)
  ServerError
  NotFound
}

fn read_file_to_response(path) {
  case file.read(path) {
    Ok(data) -> GeminiContent(data)
    _ -> ServerError
  }
}

fn build_response(path: String) -> GeminiResponse {
  let full_path = "pages/" <> path <> ".gemini"
  case file.is_file(full_path) {
    True -> read_file_to_response(full_path)
    False -> NotFound
  }
}

fn parse_scheme(request_string: String) -> ParseResult {
  case string.split(request_string, "://") {
    [scheme, host_and_path] -> ParseSuccess(scheme, host_and_path)
    _ -> ParseFailure("URL Missing scheme")
  }
}

fn parse_host(host_and_path: String) -> ParseResult {
  case string.split(host_and_path, "/") {
    [host, path] -> ParseSuccess(host, path)
    [host] -> ParseSuccess(host, "/\r\n")
  }
}

fn parse_path(path_and_control_chars: String) -> ParseResult {
  case string.ends_with(path_and_control_chars, "\r\n") {
    True -> ParseSuccess(string.drop_right(path_and_control_chars, 1), "")
    False -> ParseSuccess(path_and_control_chars, "")
  }
}

fn parse_request(request_bitstring: BitString) -> Result(String, String) {
  let assert Ok(request_string) = bit_string.to_string(request_bitstring)
  let assert ParseSuccess(_scheme, remainder) = parse_scheme(request_string)
  let assert ParseSuccess(_host, remainder) = parse_host(remainder)
  let assert ParseSuccess(path, _remainder) = parse_path(remainder)

  Ok(case path {
    "" -> "index"
    "/" -> "index"
    _ -> path
  })
}

fn handle_gemini_request(request_string) {
  let assert Ok(path) = parse_request(request_string)
  let assert response = build_response(path)

  let code = case response {
    GeminiContent(_) -> "20"
    ServerError -> "40"
    NotFound -> "51"
  }

  let full_response = case response {
    GeminiContent(data) -> code <> " text/gemini\r\n" <> data
    ServerError -> code
    NotFound -> code <> " " <> path <> " not found."
  }

  io.print("Request for path: ")
  io.print(path)
  io.print(" => Code: ")
  io.println(code)

  bit_builder.from_string(full_response)
}

pub fn main() {
  io.println("Starting gemini_server!")
  handler.func(fn(msg, state) {
    let assert Ok(_) = ssl.send(state.socket, handle_gemini_request(msg))
    let _ = ssl.close(state.socket)
    actor.Stop(process.Normal)
  })
  |> acceptor.new_pool
  |> glisten.serve_ssl(
    port: 1965,
    certfile: "server.crt",
    keyfile: "server.key",
    with_pool: _,
  )
  |> result.map(fn(_) { process.sleep_forever() })
}
