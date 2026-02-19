// store/task_store.gleam
// Хранилище задач в памяти с интерфейсом для легкой замены на БД

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import types/task.{
  type CreateTaskData, type Task, InProgress, NotStarted, Paused, Task,
}

// Типы сообщений -------------------------------------------------------------

/// Сообщения для actor хранилища
pub type TaskStoreMessage {
  GetAll(reply_to: Subject(List(Task)))
  GetById(id: Int, reply_to: Subject(Option(Task)))
  Create(data: CreateTaskData, reply_to: Subject(Task))
  Update(id: Int, updater: fn(Task) -> Task, reply_to: Subject(Option(Task)))
  Delete(id: Int, reply_to: Subject(Bool))
  StartTimer(id: Int, current_time: Int, reply_to: Subject(Option(Task)))
  StopTimer(id: Int, current_time: Int, reply_to: Subject(Option(Task)))
}

/// Тип для абстракции над хранилищем.
pub opaque type TaskStore {
  TaskStore(subject: Subject(TaskStoreMessage))
}

// Публичный API ---------------------------------------------------------------

/// Создать новое хранилище задач
pub fn new() -> TaskStore {
  let assert Ok(actor) =
    actor.new(dict.new())
    |> actor.on_message(handle_message)
    |> actor.start

  TaskStore(actor.data)
}

/// Получить все задачи
pub fn get_all(store: TaskStore) -> List(Task) {
  process.call(store.subject, 5000, GetAll)
}

/// Получить задачу по ID
pub fn get_by_id(store: TaskStore, id: Int) -> Option(Task) {
  process.call(store.subject, 5000, GetById(id, _))
}

/// Создать новую задачу
pub fn create(store: TaskStore, data: CreateTaskData) -> Task {
  process.call(store.subject, 5000, Create(data, _))
}

/// Обновить задачу
pub fn update(
  store: TaskStore,
  id: Int,
  updater: fn(Task) -> Task,
) -> Option(Task) {
  process.call(store.subject, 5000, Update(id, updater, _))
}

/// Удалить задачу
pub fn delete(store: TaskStore, id: Int) -> Bool {
  process.call(store.subject, 5000, Delete(id, _))
}

/// Запустить таймер для задачи
pub fn start_timer(store: TaskStore, id: Int, current_time: Int) -> Option(Task) {
  process.call(store.subject, 5000, StartTimer(id, current_time, _))
}

/// Остановить таймер для задачи
pub fn stop_timer(store: TaskStore, id: Int, current_time: Int) -> Option(Task) {
  process.call(store.subject, 5000, StopTimer(id, current_time, _))
}

// Внутренняя реализация (в памяти) ---------------------------------------------

type StoreState =
  Dict(Int, Task)

fn handle_message(
  state: StoreState,
  message: TaskStoreMessage,
) -> actor.Next(StoreState, TaskStoreMessage) {
  case message {
    GetAll(reply_to) -> {
      let tasks =
        dict.values(state)
        |> list.sort(fn(a, b) { int.compare(b.created_at, a.created_at) })
      process.send(reply_to, tasks)
      actor.continue(state)
    }

    GetById(id, reply_to) -> {
      process.send(reply_to, dict.get(state, id) |> option.from_result)
      actor.continue(state)
    }

    Create(data, reply_to) -> {
      let id = dict.size(state) + 1
      let task =
        Task(
          id: id,
          name: data.name,
          description: data.description,
          status: NotStarted,
          time_spent_seconds: 0,
          started_at: None,
          created_at: id,
        )
      let new_state = dict.insert(state, id, task)
      process.send(reply_to, task)
      actor.continue(new_state)
    }

    Update(id, updater, reply_to) -> {
      case dict.get(state, id) {
        Ok(task) -> {
          let updated = updater(task)
          let new_state = dict.insert(state, id, updated)
          process.send(reply_to, Some(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          process.send(reply_to, None)
          actor.continue(state)
        }
      }
    }

    Delete(id, reply_to) -> {
      let existed = dict.has_key(state, id)
      let new_state = dict.delete(state, id)
      process.send(reply_to, existed)
      actor.continue(new_state)
    }

    StartTimer(id, current_time, reply_to) -> {
      case dict.get(state, id) {
        Ok(task) -> {
          let updated = case task.status {
            NotStarted | Paused -> {
              Task(..task, status: InProgress, started_at: Some(current_time))
            }
            _ -> task
          }
          let new_state = dict.insert(state, id, updated)
          process.send(reply_to, Some(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          process.send(reply_to, None)
          actor.continue(state)
        }
      }
    }

    StopTimer(id, current_time, reply_to) -> {
      case dict.get(state, id) {
        Ok(task) -> {
          let updated = case task.status, task.started_at {
            InProgress, Some(started) -> {
              let elapsed = current_time - started
              Task(
                ..task,
                status: Paused,
                time_spent_seconds: task.time_spent_seconds + elapsed,
                started_at: None,
              )
            }
            _, _ -> task
          }
          let new_state = dict.insert(state, id, updated)
          process.send(reply_to, Some(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          process.send(reply_to, None)
          actor.continue(state)
        }
      }
    }
  }
}
