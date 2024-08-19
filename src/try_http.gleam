import gleam/erlang/process
import gleam/string_builder
import mist

// import wisp
import wisp.{type Request, type Response}

// import wisp/wisp_mist

/// The HTTP request handler- your application!
/// 
pub fn handle_request(req: Request) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- middleware(req)

  // Later we'll use templates, but for now a string will do.
  let body = string_builder.from_string("<h1>Hello, Joe!</h1>")

  // Return a 200 OK response with the body and a HTML content type.
  wisp.html_response(body, 200)
}

/// The middleware stack that the request handler uses. The stack is itself a
/// middleware function!
///
/// Middleware wrap each other, so the request travels through the stack from
/// top to bottom until it reaches the request handler, at which point the
/// response travels back up through the stack.
/// 
/// The middleware used here are the ones that are suitable for use in your
/// typical web application.
/// 
pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  // Permit browsers to simulate methods other than GET and POST using the
  // `_method` query parameter.
  let req = wisp.method_override(req)

  // Log information about the request and response.
  use <- wisp.log_request(req)

  // Return a default 500 response if the request handler crashes.
  use <- wisp.rescue_crashes

  // Rewrite HEAD requests to GET requests and return an empty body.
  use req <- wisp.handle_head(req)

  // Handle the request!
  handle_request(req)
}

pub fn main() {
  // This sets the logger to print INFO level logs, and other sensible defaults
  // for a web application.
  wisp.configure_logger()

  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  // Start the Mist web server.
  let assert Ok(_) =
    wisp.mist_handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()
}
