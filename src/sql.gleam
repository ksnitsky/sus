//// This module contains the code to run the sql queries defined in
//// `./src/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `complete_task` query
/// defined in `./src/sql/complete_task.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CompleteTaskRow {
  CompleteTaskRow(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
  )
}

/// Complete a task (stop timer if running and set status to completed)
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn complete_task(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Timestamp,
) -> Result(pog.Returned(CompleteTaskRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use status <- decode.field(3, task_status_decoder())
    use time_spent_seconds <- decode.field(4, decode.int)
    use started_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(CompleteTaskRow(
      id:,
      name:,
      description:,
      status:,
      time_spent_seconds:,
      started_at:,
      created_at:,
    ))
  }

  "-- Complete a task (stop timer if running and set status to completed)
update tasks
set
  status = 'completed',
  time_spent_seconds = time_spent_seconds + coalesce(
    extract(epoch from ($2::timestamp - started_at))::integer,
    0
  ),
  started_at = null
where
  id = $1
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_task` query
/// defined in `./src/sql/create_task.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateTaskRow {
  CreateTaskRow(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
  )
}

/// Create a new task with name and description
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_task(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
) -> Result(pog.Returned(CreateTaskRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use status <- decode.field(3, task_status_decoder())
    use time_spent_seconds <- decode.field(4, decode.int)
    use started_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(CreateTaskRow(
      id:,
      name:,
      description:,
      status:,
      time_spent_seconds:,
      started_at:,
      created_at:,
    ))
  }

  "-- Create a new task with name and description
insert into tasks
  (name, description)
values
  ($1, $2)
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Delete a task by its ID
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_task(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Delete a task by its ID
delete from tasks
where id = $1
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_all_tasks` query
/// defined in `./src/sql/get_all_tasks.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetAllTasksRow {
  GetAllTasksRow(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
  )
}

/// Get all tasks ordered by creation date (newest first)
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_all_tasks(
  db: pog.Connection,
) -> Result(pog.Returned(GetAllTasksRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use status <- decode.field(3, task_status_decoder())
    use time_spent_seconds <- decode.field(4, decode.int)
    use started_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(GetAllTasksRow(
      id:,
      name:,
      description:,
      status:,
      time_spent_seconds:,
      started_at:,
      created_at:,
    ))
  }

  "-- Get all tasks ordered by creation date (newest first)
select
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
from
  tasks
order by
  created_at desc
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_task_by_id` query
/// defined in `./src/sql/get_task_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetTaskByIdRow {
  GetTaskByIdRow(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
  )
}

/// Get a single task by its ID
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_task_by_id(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(GetTaskByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use status <- decode.field(3, task_status_decoder())
    use time_spent_seconds <- decode.field(4, decode.int)
    use started_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(GetTaskByIdRow(
      id:,
      name:,
      description:,
      status:,
      time_spent_seconds:,
      started_at:,
      created_at:,
    ))
  }

  "-- Get a single task by its ID
select
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
from
  tasks
where
  id = $1
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `start_timer` query
/// defined in `./src/sql/start_timer.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type StartTimerRow {
  StartTimerRow(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
  )
}

/// Start the timer for a task (set status to in_progress and record start time)
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn start_timer(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Timestamp,
) -> Result(pog.Returned(StartTimerRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use status <- decode.field(3, task_status_decoder())
    use time_spent_seconds <- decode.field(4, decode.int)
    use started_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(StartTimerRow(
      id:,
      name:,
      description:,
      status:,
      time_spent_seconds:,
      started_at:,
      created_at:,
    ))
  }

  "-- Start the timer for a task (set status to in_progress and record start time)
update tasks
set
  status = 'in_progress',
  started_at = $2
where
  id = $1
  and status in ('not_started', 'paused')
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.timestamp(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `stop_timer` query
/// defined in `./src/sql/stop_timer.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type StopTimerRow {
  StopTimerRow(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
  )
}

/// Stop the timer for a task (pause it and accumulate elapsed time)
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn stop_timer(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
) -> Result(pog.Returned(StopTimerRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.string)
    use status <- decode.field(3, task_status_decoder())
    use time_spent_seconds <- decode.field(4, decode.int)
    use started_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(StopTimerRow(
      id:,
      name:,
      description:,
      status:,
      time_spent_seconds:,
      started_at:,
      created_at:,
    ))
  }

  "-- Stop the timer for a task (pause it and accumulate elapsed time)
update tasks
set
  status = 'paused',
  time_spent_seconds = time_spent_seconds + $2,
  started_at = null
where
  id = $1
  and status = 'in_progress'
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `task_status` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type TaskStatus {
  Paused
  Completed
  InProgress
  NotStarted
}

fn task_status_decoder() -> decode.Decoder(TaskStatus) {
  use task_status <- decode.then(decode.string)
  case task_status {
    "paused" -> decode.success(Paused)
    "completed" -> decode.success(Completed)
    "in_progress" -> decode.success(InProgress)
    "not_started" -> decode.success(NotStarted)
    _ -> decode.failure(Paused, "TaskStatus")
  }
}
