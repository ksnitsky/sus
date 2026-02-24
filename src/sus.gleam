import envoy
import gleam/erlang/process
import gleam/io
import gleam/result
import mist
import pog
import router
import store/task_store

pub fn main() {
  let database_url =
    envoy.get("DATABASE_URL")
    |> result.unwrap("postgres://postgres@localhost:5432/sus")

  let pool_name = process.new_name("db_pool")
  let assert Ok(config) = pog.url_config(pool_name, database_url)
  let assert Ok(started) =
    config
    |> pog.pool_size(10)
    |> pog.start

  let db = started.data
  io.println("Connected to PostgreSQL")

  let store = task_store.new(db)

  let assert Ok(_) =
    router.handle_request(_, store)
    |> mist.new
    |> mist.bind("localhost")
    |> mist.port(1234)
    |> mist.start

  process.sleep_forever()
}
