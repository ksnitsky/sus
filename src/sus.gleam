import gleam/erlang/process
import mist
import router
import store/task_store

pub fn main() {
  let store = task_store.new()

  let assert Ok(_) =
    router.handle_request(_, store)
    |> mist.new
    |> mist.bind("localhost")
    |> mist.port(1234)
    |> mist.start

  process.sleep_forever()
}
