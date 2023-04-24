import gleam/io
import gleam/bit_builder
import gleam/erlang/process
import gleam/otp/actor
import gleam/result
import glisten/acceptor
import glisten/handler
import glisten/ssl
import glisten

fn do_something(_request_string) {
  bit_builder.from_string("20 text/gemini\r\n# Hello Gemini")
}

pub fn main() {
  io.println("Starting gemini_server!")
  handler.func(fn(msg, state) {
    let assert Ok(_) = ssl.send(state.socket, do_something(msg))
    actor.Continue(state)
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
