import gleam/io
import gleam/bit_builder
import gleam/erlang/process
import gleam/otp/actor
import gleam/result
import glisten/acceptor
import glisten/handler
import glisten/ssl
import glisten

fn build_response(_path: String) -> Result(String, String) {
  Ok("20 text/gemini\r\n# Hello Gemini")
}

fn parse_request(_request_string: BitString) -> Result(String, String) {
  Ok("/")
}

fn handle_gemini_request(request_string) {
  let assert Ok(path) = parse_request(request_string)
  let assert Ok(build_response) = build_response(path)
  bit_builder.from_string(build_response)
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
