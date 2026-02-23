// store/task_store.gleam
// Task storage using PostgreSQL via pog + squirrel-generated queries

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp.{type Timestamp}
import pog
import sql
import types/task.{type CreateTaskData, type Task, Task}

/// Opaque wrapper around pog connection
pub opaque type TaskStore {
  TaskStore(db: pog.Connection)
}

/// Create new task store wrapping a pog connection
pub fn new(db: pog.Connection) -> TaskStore {
  TaskStore(db:)
}

/// Get all tasks
pub fn get_all(store: TaskStore) -> List(Task) {
  case sql.get_all_tasks(store.db) {
    Ok(pog.Returned(_count, rows)) ->
      list.map(rows, fn(r) {
        Task(
          id: r.id,
          name: r.name,
          description: r.description,
          status: r.status,
          time_spent_seconds: r.time_spent_seconds,
          started_at: r.started_at,
          created_at: r.created_at,
        )
      })
    Error(_) -> []
  }
}

/// Get task by ID
pub fn get_by_id(store: TaskStore, id: Int) -> Option(Task) {
  case sql.get_task_by_id(store.db, id) {
    Ok(pog.Returned(_, [r, ..])) ->
      Some(Task(
        id: r.id,
        name: r.name,
        description: r.description,
        status: r.status,
        time_spent_seconds: r.time_spent_seconds,
        started_at: r.started_at,
        created_at: r.created_at,
      ))
    _ -> None
  }
}

/// Create new task
pub fn create(store: TaskStore, data: CreateTaskData) -> Option(Task) {
  case sql.create_task(store.db, data.name, data.description) {
    Ok(pog.Returned(_, [r, ..])) ->
      Some(Task(
        id: r.id,
        name: r.name,
        description: r.description,
        status: r.status,
        time_spent_seconds: r.time_spent_seconds,
        started_at: r.started_at,
        created_at: r.created_at,
      ))
    _ -> None
  }
}

/// Delete task
pub fn delete(store: TaskStore, id: Int) -> Bool {
  case sql.delete_task(store.db, id) {
    Ok(pog.Returned(count, _)) -> count > 0
    Error(_) -> False
  }
}

/// Start timer for task
pub fn start_timer(
  store: TaskStore,
  id: Int,
  current_time: Timestamp,
) -> Option(Task) {
  case sql.start_timer(store.db, id, current_time) {
    Ok(pog.Returned(_, [r, ..])) ->
      Some(Task(
        id: r.id,
        name: r.name,
        description: r.description,
        status: r.status,
        time_spent_seconds: r.time_spent_seconds,
        started_at: r.started_at,
        created_at: r.created_at,
      ))
    _ -> None
  }
}

/// Stop timer for task (calculates elapsed seconds and accumulates)
pub fn stop_timer(
  store: TaskStore,
  id: Int,
  current_time: Timestamp,
) -> Option(Task) {
  // First get the task to calculate elapsed time
  case get_by_id(store, id) {
    Some(t) -> {
      case t.started_at {
        Some(started) -> {
          let elapsed = timestamp_diff_seconds(current_time, started)
          case sql.stop_timer(store.db, id, elapsed) {
            Ok(pog.Returned(_, [r, ..])) ->
              Some(Task(
                id: r.id,
                name: r.name,
                description: r.description,
                status: r.status,
                time_spent_seconds: r.time_spent_seconds,
                started_at: r.started_at,
                created_at: r.created_at,
              ))
            _ -> None
          }
        }
        None -> None
      }
    }
    None -> None
  }
}

/// Complete a task (stops timer if running)
pub fn complete_task(
  store: TaskStore,
  id: Int,
  current_time: Timestamp,
) -> Option(Task) {
  case sql.complete_task(store.db, id, current_time) {
    Ok(pog.Returned(_, [r, ..])) ->
      Some(Task(
        id: r.id,
        name: r.name,
        description: r.description,
        status: r.status,
        time_spent_seconds: r.time_spent_seconds,
        started_at: r.started_at,
        created_at: r.created_at,
      ))
    _ -> None
  }
}

// Internal helpers -----------------------------------------------------------

/// Calculate difference between two timestamps in seconds
fn timestamp_diff_seconds(later: Timestamp, earlier: Timestamp) -> Int {
  let #(later_s, _) = timestamp.to_unix_seconds_and_nanoseconds(later)
  let #(earlier_s, _) = timestamp.to_unix_seconds_and_nanoseconds(earlier)
  later_s - earlier_s
}
