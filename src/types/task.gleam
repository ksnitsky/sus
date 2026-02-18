// types/task.gleam
// Общие типы для задач, используются во всём приложении

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}

/// Статус задачи
pub type TaskStatus {
  NotStarted
  InProgress
  Completed
  Paused
}

/// Задача с таймером
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

/// Данные для создания новой задачи
pub type CreateTaskData {
  CreateTaskData(name: String, description: String)
}

/// Получить отображаемое название статуса
pub fn status_to_string(status: TaskStatus) -> String {
  case status {
    NotStarted -> "Не начата"
    InProgress -> "В работе"
    Completed -> "Завершена"
    Paused -> "На паузе"
  }
}

/// Преобразовать статус в строку для CSS-класса
pub fn status_to_class(status: TaskStatus) -> String {
  case status {
    NotStarted -> "status-not-started"
    InProgress -> "status-in-progress"
    Completed -> "status-completed"
    Paused -> "status-paused"
  }
}

/// Форматировать секунды в читаемый формат (ЧЧ:ММ:СС или ММ:СС)
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

/// Получить текущее время в секундах (Unix timestamp)
@external(erlang, "erlang", "system_time")
pub fn now() -> Int

/// JSON encoder для Task
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

/// JSON decoder для CreateTaskData
pub fn create_task_data_decoder() {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  decode.success(CreateTaskData(name:, description:))
}
