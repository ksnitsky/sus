import components/layout
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import gleam/time/timestamp.{type Timestamp}
import lustre.{type App}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import sql.{Completed, InProgress, NotStarted, Paused}
import store/task_store.{type TaskStore}
import types/task.{
  type Task, CreateTaskData, format_duration, status_to_class, status_to_string,
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(
    tasks: List(Task),
    new_task_name: String,
    new_task_description: String,
    store: TaskStore,
    current_time: Timestamp,
  )
}

pub fn init(store: TaskStore) -> Model {
  let tasks = task_store.get_all(store)
  Model(
    tasks: tasks,
    new_task_name: "",
    new_task_description: "",
    store: store,
    current_time: task.now(),
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  // Task creation form
  UserChangedTaskName(String)
  UserChangedTaskDescription(String)
  UserClickedAddTask

  // Task management
  UserClickedStartTask(Int)
  UserClickedPauseTask(Int)
  UserClickedCompleteTask(Int)
  UserClickedDeleteTask(Int)

  // Timer
  Tick
  CheckActiveTimers
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserChangedTaskName(name) -> #(
      Model(..model, new_task_name: name),
      effect.none(),
    )

    UserChangedTaskDescription(description) -> #(
      Model(..model, new_task_description: description),
      effect.none(),
    )

    UserClickedAddTask ->
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

    UserClickedStartTask(id) -> {
      let now = task.now()
      let _ = task_store.start_timer(model.store, id, now)
      let tasks = task_store.get_all(model.store)
      let has_active = list.any(tasks, fn(t) { t.status == InProgress })
      let tick_effect = case has_active {
        True -> schedule_tick()
        False -> effect.none()
      }
      #(Model(..model, tasks: tasks, current_time: now), tick_effect)
    }

    Tick -> {
      let new_time = task.now()
      let has_active = list.any(model.tasks, fn(t) { t.status == InProgress })
      let next_effect = case has_active {
        True -> schedule_tick()
        False -> effect.none()
      }
      #(Model(..model, current_time: new_time), next_effect)
    }

    CheckActiveTimers -> {
      let has_active = list.any(model.tasks, fn(t) { t.status == InProgress })
      let tick_effect = case has_active {
        True -> schedule_tick()
        False -> effect.none()
      }
      #(model, tick_effect)
    }

    UserClickedPauseTask(id) -> {
      let now = task.now()
      let _ = task_store.stop_timer(model.store, id, now)
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks, current_time: now), effect.none())
    }

    UserClickedCompleteTask(id) -> {
      let now = task.now()
      let _ = task_store.complete_task(model.store, id, now)
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks, current_time: now), effect.none())
    }

    UserClickedDeleteTask(id) -> {
      let _ = task_store.delete(model.store, id)
      let tasks = task_store.get_all(model.store)
      #(Model(..model, tasks: tasks), effect.none())
    }
  }
}

// Timer -----------------------------------------------------------------------

/// Start a timer in a background.
/// Each task spawns timer for itself when user pressed start task.
fn schedule_tick() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ =
      process.spawn(fn() {
        process.sleep(1000)
        dispatch(Tick)
      })

    Nil
  })
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

fn task_list(tasks: List(Task), current_time: Timestamp) -> Element(Msg) {
  case tasks {
    [] -> empty_state()
    _ ->
      html.ul(
        [attribute.class("task-list")],
        list.map(tasks, fn(t) { task_item(t, current_time) }),
      )
  }
}

fn empty_state() -> Element(Msg) {
  html.div([attribute.class("empty-state")], [
    html.h3([], [html.text("Нет задач")]),
    html.p([], [html.text("Добавьте свою первую задачу выше!")]),
  ])
}

fn task_item(t: Task, current_time: Timestamp) -> Element(Msg) {
  let status_class = status_to_class(t.status)
  let display_time = case t.status, t.started_at {
    InProgress, Some(started) ->
      t.time_spent_seconds
      + {
        task.timestamp_to_seconds(current_time)
        - task.timestamp_to_seconds(started)
      }
    _, _ -> t.time_spent_seconds
  }

  html.li([attribute.class("task-item " <> status_class)], [
    html.div([attribute.class("task-header")], [
      html.h3([attribute.class("task-name")], [html.text(t.name)]),
      html.span([attribute.class("task-status " <> status_class)], [
        html.text(status_to_string(t.status)),
      ]),
    ]),
    case t.description {
      "" -> html.div([], [])
      desc -> html.p([attribute.class("task-description")], [html.text(desc)])
    },
    html.div([attribute.class("task-footer")], [
      html.span([attribute.class("task-time")], [
        html.text(format_duration(display_time)),
      ]),
      html.div([attribute.class("task-actions")], task_actions(t)),
    ]),
  ])
}

fn task_actions(t: Task) -> List(Element(Msg)) {
  case t.status {
    NotStarted | Paused -> [
      html.button(
        [
          attribute.class("btn btn-success"),
          event.on_click(UserClickedStartTask(t.id)),
        ],
        [html.text("▶ Старт")],
      ),
      html.button(
        [
          attribute.class("btn btn-danger"),
          event.on_click(UserClickedDeleteTask(t.id)),
        ],
        [html.text("🗑 Удалить")],
      ),
    ]

    InProgress -> [
      html.button(
        [
          attribute.class("btn btn-warning"),
          event.on_click(UserClickedPauseTask(t.id)),
        ],
        [html.text("⏸ Пауза")],
      ),
      html.button(
        [
          attribute.class("btn btn-success"),
          event.on_click(UserClickedCompleteTask(t.id)),
        ],
        [html.text("✓ Завершить")],
      ),
    ]

    Completed -> [
      html.button(
        [
          attribute.class("btn btn-danger"),
          event.on_click(UserClickedDeleteTask(t.id)),
        ],
        [html.text("🗑 Удалить")],
      ),
    ]
  }
}

// COMPONENT -------------------------------------------------------------------

fn init_with_store(store: TaskStore) -> #(Model, Effect(Msg)) {
  let check_effect = effect.from(fn(dispatch) { dispatch(CheckActiveTimers) })

  #(init(store), check_effect)
}

pub fn component(store: TaskStore) -> App(_, Model, Msg) {
  lustre.application(
    init: fn(_) { init_with_store(store) },
    update: update,
    view: view,
  )
}
