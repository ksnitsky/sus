// types/task.gleam
// Common types for tasks, used throughout the application

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}

/// Task status
pub type TaskStatus {
  NotStarted
  InProgress
  Completed
  Paused
}

/// Task with timer
pub type Task {
  Task(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Int),
    created_at: Int,
  )
}

/// Data for creating new task
pub type CreateTaskData {
  CreateTaskData(name: String, description: String)
}

/// Get display name for status (UI text in Russian)
pub fn status_to_string(status: TaskStatus) -> String {
  case status {
    NotStarted -> "Не начата"
    InProgress -> "В работе"
    Completed -> "Завершена"
    Paused -> "На паузе"
  }
}

/// Convert status to CSS class string
pub fn status_to_class(status: TaskStatus) -> String {
  case status {
    NotStarted -> "status-not-started"
    InProgress -> "status-in-progress"
    Completed -> "status-completed"
    Paused -> "status-paused"
  }
}

/// Format seconds to readable format (HH:MM:SS or MM:SS)
pub fn format_duration(seconds: Int) -> String {
  let hours = seconds / 3600
  let minutes = { seconds % 3600 } / 60
  let secs = seconds % 60

  case hours > 0 {
    True -> {
      int.to_string(hours) <> ":" <> pad_zero(minutes) <> ":" <> pad_zero(secs)
    }
    False -> {
      int.to_string(minutes) <> ":" <> pad_zero(secs)
    }
  }
}

fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}

/// Get current time in seconds (Unix timestamp)
@external(erlang, "erlang", "system_time")
pub fn now_internal() -> Int

/// Get current time in seconds (Unix timestamp)
pub fn now() -> Int {
  now_internal() / 1_000_000_000
}

/// JSON encoder for Task
pub fn task_to_json(task: Task) -> json.Json {
  json.object([
    #("id", json.int(task.id)),
    #("name", json.string(task.name)),
    #("description", json.string(task.description)),
    #("status", json.string(status_to_string(task.status))),
    #("time_spent_seconds", json.int(task.time_spent_seconds)),
    #("started_at", case task.started_at {
      option.Some(t) -> json.int(t)
      option.None -> json.null()
    }),
    #("created_at", json.int(task.created_at)),
  ])
}

/// JSON decoder for CreateTaskData
pub fn create_task_data_decoder() {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  decode.success(CreateTaskData(name:, description:))
}
