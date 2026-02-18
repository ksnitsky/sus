# AGENTS.md

## Проект: Task Tracker (sus)

**Стек:** Gleam + Lustre (server components) + Mist (HTTP сервер) + OTP Actor

**Запуск:**
```bash
gleam run   # http://localhost:1234
gleam test  # запуск тестов
```

**Важно:** Не запускай сервер (`gleam run`) самостоятельно. Предоставь команду пользователю, чтобы он запустил её сам.

## Архитектура

### Структура
- `src/sus.gleam` - точка входа, запуск HTTP сервера
- `src/router.gleam` - маршрутизация: HTML, JS runtime, WebSocket
- `src/pages/tasks.gleam` - Lustre компонент (Model/Update/View)
- `src/store/task_store.gleam` - in-memory хранилище через OTP actor
- `src/types/task.gleam` - типы Task, TaskStatus + JSON кодирование
- `src/components/layout.gleam` - общий layout + inline CSS

### Ключевые паттерны

**1. Server Components (Lustre)**
- Компонент работает на сервере, UI рендерится через WebSocket
- `pages/tasks.gleam` - полноценное Lustre приложение (init/update/view)
- WebSocket endpoint: `/ws/tasks`

**2. Task Store (OTP Actor)**
- Хранилище в памяти через `gleam_otp/actor`
- Асинхронные сообщения с таймаутом 5000ms
- Интерфейс позволяет легко заменить на БД

**3. Таймер задач**
- `time_spent_seconds` - накопленное время
- `started_at` - timestamp запуска (None когда пауза)
- Для активных задач время считается: `time_spent + (now - started_at)`

### Типы данных

```gleam
// Статусы
NotStarted | InProgress | Completed | Paused

// Задача
type Task {
  id: Int,
  name: String,
  description: String,
  status: TaskStatus,
  time_spent_seconds: Int,
  started_at: Option(Int),  // Unix timestamp
  created_at: Int,
}
```

### API хранилища

```gleam
task_store.new() -> TaskStore
task_store.get_all(store) -> List(Task)
task_store.get_by_id(store, id) -> Option(Task)
task_store.create(store, data) -> Task
task_store.update(store, id, updater) -> Option(Task)
task_store.delete(store, id) -> Bool
task_store.start_timer(store, id, current_time) -> Option(Task)
task_store.stop_timer(store, id, current_time) -> Option(Task)
```

### CSS классы статусов

- `status-not-started` - серая рамка
- `status-in-progress` - синяя рамка
- `status-completed` - зелёная рамка
- `status-paused` - оранжевая рамка

## Ограничения

- Хранилище в памяти - данные теряются при перезапуске
- Нет персистентности
- Нет валидации входных данных
- Нет аутентификации
- Таймер обновляется только при действиях (нет периодического Tick)

## Зависимости

- `lustre` - фреймворк для UI
- `mist` - HTTP/WebSocket сервер
- `gleam_json` - JSON кодирование
- `gleam_otp` - OTP процессы
- `gleam_erlang` - FFI для Erlang

## Тесты

- `test/sus_test.gleam` - базовые тесты
- Используется `gleeunit` для тестирования
