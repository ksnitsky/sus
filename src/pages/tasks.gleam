// pages/tasks.gleam
// Server component для страницы списка задач

import components/layout
import gleam/list
import gleam/option.{Some}
import lustre.{type App}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import store/task_store.{type TaskStore}
import types/task.{
  type CreateTaskData, type Task, Completed, CreateTaskData, InProgress,
  NotStarted, Paused, Task, format_duration, status_to_class, status_to_string,
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(
    tasks: List(Task),
    new_task_name: String,
    new_task_description: String,
    store: TaskStore,
    current_time: Int,
  )
}

pub fn init(store: TaskStore) -> Model {
  let tasks = task_store.get_all(store)
  Model(
    tasks: tasks,
    new_task_name: "",
    new_task_description: "",
    store: store,
    current_time: task.now() / 1_000_000_000,
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  // Форма создания задачи
  UserChangedTaskName(String)
  UserChangedTaskDescription(String)
  UserClickedAddTask

  // Управление задачами
  UserClickedStartTask(Int)
  UserClickedPauseTask(Int)
  UserClickedCompleteTask(Int)
  UserClickedDeleteTask(Int)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserChangedTaskName(name) -> {
      #(Model(..model, new_task_name: name), effect.none())
    }

    UserChangedTaskDescription(description) -> {
      #(Model(..model, new_task_description: description), effect.none())
    }

    UserClickedAddTask -> {
      case model.new_task_name {
        "" -> #(model, effect.none())
        _ -> {
          let data =
            CreateTaskData(
              name: model.new_task_name,
              description: model.new_task_description,
            )
          let _ = task_store.create(model.store, data)
          let tasks = task_store.get_all(model.store)
          #(
            Model(
              ..model,
              tasks: tasks,
              new_task_name: "",
              new_task_description: "",
            ),
            effect.none(),
          )
        }
      }
    }

    UserClickedStartTask(id) -> {
      let _ = task_store.start_timer(model.store, id, model.current_time)
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks), effect.none())
    }

    UserClickedPauseTask(id) -> {
      let _ = task_store.stop_timer(model.store, id, model.current_time)
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks), effect.none())
    }

    UserClickedCompleteTask(id) -> {
      // Сначала останавливаем таймер если запущен
      let _ = task_store.stop_timer(model.store, id, model.current_time)
      // Затем обновляем статус
      let _ =
        task_store.update(model.store, id, fn(task) {
          Task(..task, status: Completed)
        })
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks), effect.none())
    }

    UserClickedDeleteTask(id) -> {
      let _ = task_store.delete(model.store, id)
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks), effect.none())
    }
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  layout.layout("Task Tracker - Список задач", [
    task_form(model),
    task_list(model.tasks, model.current_time),
  ])
}

fn task_form(model: Model) -> Element(Msg) {
  html.div([attribute.class("task-form")], [
    html.h2([], [html.text("Добавить задачу")]),
    html.div([attribute.class("form-group")], [
      html.label([], [html.text("Название")]),
      html.input([
        attribute.type_("text"),
        attribute.value(model.new_task_name),
        attribute.placeholder("Название задачи..."),
        event.on_input(UserChangedTaskName),
      ]),
    ]),
    html.div([attribute.class("form-group")], [
      html.label([], [html.text("Описание")]),
      html.textarea(
        [
          attribute.value(model.new_task_description),
          attribute.placeholder("Описание задачи (опционально)..."),
          event.on_input(UserChangedTaskDescription),
        ],
        "",
      ),
    ]),
    html.button(
      [attribute.class("btn btn-primary"), event.on_click(UserClickedAddTask)],
      [html.text("Добавить задачу")],
    ),
  ])
}

fn task_list(tasks: List(Task), current_time: Int) -> Element(Msg) {
  case tasks {
    [] -> empty_state()
    _ ->
      html.ul(
        [attribute.class("task-list")],
        list.map(tasks, fn(task) { task_item(task, current_time) }),
      )
  }
}

fn empty_state() -> Element(Msg) {
  html.div([attribute.class("empty-state")], [
    html.h3([], [html.text("Нет задач")]),
    html.p([], [html.text("Добавьте свою первую задачу выше!")]),
  ])
}

fn task_item(task: Task, current_time: Int) -> Element(Msg) {
  let status_class = status_to_class(task.status)
  let display_time = case task.status, task.started_at {
    InProgress, Some(started) -> {
      // Для активной задачи показываем накопленное + время с момента старта
      task.time_spent_seconds + { current_time - started }
    }
    _, _ -> task.time_spent_seconds
  }

  html.li([attribute.class("task-item " <> status_class)], [
    html.div([attribute.class("task-header")], [
      html.h3([attribute.class("task-name")], [html.text(task.name)]),
      html.span([attribute.class("task-status " <> status_class)], [
        html.text(status_to_string(task.status)),
      ]),
    ]),

    case task.description {
      "" -> html.div([], [])
      desc -> html.p([attribute.class("task-description")], [html.text(desc)])
    },

    html.div([attribute.class("task-footer")], [
      html.span([attribute.class("task-time")], [
        html.text(format_duration(display_time)),
      ]),
      html.div([attribute.class("task-actions")], task_actions(task)),
    ]),
  ])
}

fn task_actions(task: Task) -> List(Element(Msg)) {
  case task.status {
    NotStarted | Paused -> [
      html.button(
        [
          attribute.class("btn btn-success"),
          event.on_click(UserClickedStartTask(task.id)),
        ],
        [html.text("▶ Старт")],
      ),
      html.button(
        [
          attribute.class("btn btn-danger"),
          event.on_click(UserClickedDeleteTask(task.id)),
        ],
        [html.text("🗑 Удалить")],
      ),
    ]

    InProgress -> [
      html.button(
        [
          attribute.class("btn btn-warning"),
          event.on_click(UserClickedPauseTask(task.id)),
        ],
        [html.text("⏸ Пауза")],
      ),
      html.button(
        [
          attribute.class("btn btn-success"),
          event.on_click(UserClickedCompleteTask(task.id)),
        ],
        [html.text("✓ Завершить")],
      ),
    ]

    Completed -> [
      html.button(
        [
          attribute.class("btn btn-danger"),
          event.on_click(UserClickedDeleteTask(task.id)),
        ],
        [html.text("🗑 Удалить")],
      ),
    ]
  }
}

// COMPONENT -------------------------------------------------------------------

fn init_with_store(store: TaskStore) -> #(Model, Effect(Msg)) {
  #(init(store), effect.none())
}

pub fn component(store: TaskStore) -> App(_, Model, Msg) {
  lustre.application(
    init: fn(_) { init_with_store(store) },
    update: update,
    view: view,
  )
}
