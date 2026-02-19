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
- `src/sus.gleam` - entry point, HTTP server startup
- `src/router.gleam` - routing: HTML, JS runtime, WebSocket
- `src/pages/tasks.gleam` - Lustre component (Model/Update/View)
- `src/store/task_store.gleam` - in-memory storage via OTP actor
- `src/types/task.gleam` - Task, TaskStatus types + JSON encoding
- `src/components/layout.gleam` - shared layout + inline CSS
- `src/middleware/logger.gleam` - HTTP request logging middleware

### Ключевые паттерны

**1. Server Components (Lustre)**
- Компонент работает на сервере, UI рендерится через WebSocket
- `pages/tasks.gleam` - полноценное Lustre приложение (init/update/view)
- WebSocket endpoint: `/ws/tasks`

**2. Task Store (OTP Actor)**
- Хранилище в памяти через `gleam_otp/actor`
- Асинхронные сообщения с таймаутом 5000ms
- Интерфейс позволяет легко заменить на БД

**3. Таймер задач (Time Tracking)**

The timer uses a dual-field approach to track time without periodic updates:

```gleam
type Task {
  time_spent_seconds: Int,     // Accumulated time (stored permanently)
  started_at: Option(Int),     // Unix timestamp when timer started (None when paused)
  status: TaskStatus,          // NotStarted | InProgress | Paused | Completed
}
```

**How it works:**
- `start_timer(store, id, current_time)` - Sets `started_at = Some(current_time)` and status = InProgress
- `stop_timer(store, id, current_time)` - Calculates elapsed time: `current_time - started_at`, adds to `time_spent_seconds`, sets `started_at = None` and status = Paused
- **Display calculation**: For active tasks: `time_spent_seconds + (now - started_at)`

**Important**: The timer uses a periodic Tick (every second) to update the UI for active tasks. Each task spawns its own timer when started.

**4. HTTP Request Logging**

```gleam
// router.gleam
use <- logger.log_request(request)
```

Format: `METHOD /path STATUS duration_ms`

Example:
```
GET / 200 5ms
GET /lustre/runtime.mjs 200 2ms
POST /ws/tasks 200 15ms
```

Implementation uses Erlang's `erlang:system_time/1` for timing and `io:format/2` for output to stderr.

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

## Code Style

**Important**: All code comments must be written in **English only**. This ensures consistency and makes the codebase accessible to all contributors.

## Ограничения

- Хранилище в памяти - данные теряются при перезапуске
- Нет персистентности
- Нет валидации входных данных
- Нет аутентификации
- Таймер использует периодический Tick каждую секунду для обновления отображения активных задач

## Зависимости

- `lustre` - фреймворк для UI
- `mist` - HTTP/WebSocket сервер
- `gleam_json` - JSON кодирование
- `gleam_otp` - OTP процессы
- `gleam_erlang` - FFI для Erlang

## Тесты

- `test/sus_test.gleam` - базовые тесты
- Используется `gleeunit` для тестирования
