// types/task.gleam
// Common types and utilities for tasks

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import sql.{type TaskStatus, Completed, InProgress, NotStarted, Paused}

/// Task with timer
pub type Task {
  Task(
    id: Int,
    name: String,
    description: String,
    status: TaskStatus,
    time_spent_seconds: Int,
    started_at: Option(Timestamp),
    created_at: Timestamp,
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

/// Get current time as Timestamp
pub fn now() -> Timestamp {
  timestamp.system_time()
}

/// Get current time in unix seconds for timer display
pub fn now_seconds() -> Int {
  let #(s, _ns) = timestamp.to_unix_seconds_and_nanoseconds(now())
  s
}

/// Convert Timestamp to unix seconds for timer calculations
pub fn timestamp_to_seconds(ts: Timestamp) -> Int {
  let #(s, _ns) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  s
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
      option.Some(t) -> json.int(timestamp_to_seconds(t))
      option.None -> json.null()
    }),
    #("created_at", json.int(timestamp_to_seconds(task.created_at))),
  ])
}

/// JSON decoder for CreateTaskData
pub fn create_task_data_decoder() {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  decode.success(CreateTaskData(name:, description:))
}
