// router.gleam
// Application router

import gleam/bytes_tree
import gleam/erlang/application
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string_tree
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/server_component
import middleware/logger
import mist.{type Connection, type ResponseData}
import pages/tasks
import store/task_store.{type TaskStore}

pub fn handle_request(
  request: Request(Connection),
  store: TaskStore,
) -> Response(ResponseData) {
  use <- logger.log_request(request)
  handle_request_inner(request, store)
}

fn handle_request_inner(
  request: Request(Connection),
  store: TaskStore,
) -> Response(ResponseData) {
  case request.path_segments(request) {
    [] -> serve_html()

    ["lustre", "runtime.mjs"] -> serve_runtime()

    ["static", "styles.css"] -> serve_css()

    ["ws", "tasks"] -> serve_tasks(request, store)

    _ -> response.set_body(response.new(404), mist.Bytes(bytes_tree.new()))
  }
}

// HTML ------------------------------------------------------------------------

fn serve_html() -> Response(ResponseData) {
  let html_string =
    html.html([attribute.lang("ru")], [
      html.head([], [
        html.meta([attribute.charset("utf-8")]),
        html.meta([
          attribute.name("viewport"),
          attribute.content("width=device-width, initial-scale=1"),
        ]),
        html.title([], "Task Tracker"),
        html.link([
          attribute.rel("stylesheet"),
          attribute.href("/static/styles.css"),
        ]),
        html.script(
          [attribute.type_("module"), attribute.src("/lustre/runtime.mjs")],
          "",
        ),
      ]),
      html.body(
        [
          attribute.styles([
            #("max-width", "800px"),
            #("margin", "0 auto"),
            #("padding", "20px"),
          ]),
        ],
        [
          html.header([], [html.h1([], [html.text("Task Tracker")])]),
          html.main([], [
            server_component.element([server_component.route("/ws/tasks")], []),
          ]),
          html.footer(
            [
              attribute.styles([
                #("margin-top", "40px"),
                #("text-align", "center"),
                #("color", "#666"),
              ]),
            ],
            [html.text("Task Tracker \u{00A9} 2025")],
          ),
        ],
      ),
    ])
    |> element.to_string

  let html =
    { "<!DOCTYPE html>" <> html_string }
    |> string_tree.from_string
    |> bytes_tree.from_string_tree

  response.new(200)
  |> response.set_body(mist.Bytes(html))
  |> response.set_header("content-type", "text/html")
}

// STATIC ASSETS ---------------------------------------------------------------

fn serve_runtime() -> Response(ResponseData) {
  let assert Ok(lustre_priv) = application.priv_directory("lustre")
  let file_path = lustre_priv <> "/static/lustre-server-component.mjs"

  case mist.send_file(file_path, offset: 0, limit: None) {
    Ok(file) ->
      response.new(200)
      |> response.prepend_header("content-type", "application/javascript")
      |> response.prepend_header(
        "cache-control",
        "public, max-age=86400, immutable",
      )
      |> response.set_body(file)

    Error(_) ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}

fn serve_css() -> Response(ResponseData) {
  let assert Ok(app_priv) = application.priv_directory("sus")
  let file_path = app_priv <> "/static/styles.css"

  case mist.send_file(file_path, offset: 0, limit: None) {
    Ok(file) ->
      response.new(200)
      |> response.prepend_header("content-type", "text/css")
      |> response.prepend_header(
        "cache-control",
        "public, max-age=86400, immutable",
      )
      |> response.set_body(file)

    Error(_) ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}

// WEBSOCKET -------------------------------------------------------------------

fn serve_tasks(
  request: Request(Connection),
  store: TaskStore,
) -> Response(ResponseData) {
  mist.websocket(
    request: request,
    on_init: fn(_) { init_tasks_socket(store) },
    handler: loop_tasks_socket,
    on_close: close_tasks_socket,
  )
}

type TasksSocket {
  TasksSocket(
    component: lustre.Runtime(tasks.Msg),
    self: Subject(server_component.ClientMessage(tasks.Msg)),
  )
}

type TasksSocketMessage =
  server_component.ClientMessage(tasks.Msg)

type TasksSocketInit =
  #(TasksSocket, Option(Selector(TasksSocketMessage)))

fn init_tasks_socket(store: TaskStore) -> TasksSocketInit {
  let tasks_component = tasks.component(store)
  let assert Ok(component) = lustre.start_server_component(tasks_component, Nil)

  let self = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(self)

  server_component.register_subject(self)
  |> lustre.send(to: component)

  #(TasksSocket(component:, self:), Some(selector))
}

fn loop_tasks_socket(
  state: TasksSocket,
  message: mist.WebsocketMessage(TasksSocketMessage),
  connection: mist.WebsocketConnection,
) -> mist.Next(TasksSocket, TasksSocketMessage) {
  case message {
    mist.Text(json) -> {
      case json.parse(json, server_component.runtime_message_decoder()) {
        Ok(runtime_message) -> lustre.send(state.component, runtime_message)
        Error(_) -> Nil
      }
      mist.continue(state)
    }

    mist.Binary(_) -> {
      mist.continue(state)
    }

    mist.Custom(client_message) -> {
      let json = server_component.client_message_to_json(client_message)
      let assert Ok(_) = mist.send_text_frame(connection, json.to_string(json))
      mist.continue(state)
    }

    mist.Closed | mist.Shutdown -> mist.stop()
  }
}

fn close_tasks_socket(state: TasksSocket) -> Nil {
  lustre.shutdown()
  |> lustre.send(to: state.component)
}
