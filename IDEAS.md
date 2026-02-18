# Идеи и альтернативные решения

## Проблема: Обновление таймера задач в реальном времени

Текущее решение: OTP actor с `process.sleep(1000)` в эффекте Lustre.

---

## Вариант 1: Client-Side JavaScript (самый простой и эффективный)

**Идея:** Перенести логику таймера на клиент, сервер только отдает начальные данные.

**Реализация:**
- Отдавать в HTML `data-started-at` и `data-time-spent`
- JavaScript hook считает `time_spent + (now - started_at)` каждую секунду
- При действиях (пауза/старт) сервер отправляет новые данные

**Плюсы:**
- Нет нагрузки на сервер
- Работает даже при плохом соединении
- Мгновенные обновления без задержки сети

**Минусы:**
- Нужно писать JavaScript
- Рассинхронизация если клиент меняет время

**Пример из Phoenix:**
```elixir
# В шаблоне
<div id="timer" phx-hook="Timer" data-started-at={@started_at} data-spent={@time_spent}>
  <%= format_time(@display_time) %>
</div>

# JavaScript hook
const Timer = {
  mounted() {
    this.interval = setInterval(() => {
      const now = Math.floor(Date.now() / 1000);
      const elapsed = now - this.startedAt;
      const total = this.spent + elapsed;
      this.el.textContent = this.formatTime(total);
    }, 1000);
  },
  destroyed() {
    clearInterval(this.interval);
  }
};
```

---

## Вариант 2: PubSub для распределенных таймеров

**Идея:** Когда несколько пользователей видят один таймер (shared timer).

**Реализация:**
- Один OTP процесс для таймера на группу/команду
- PubSub рассылка обновлений всем подписчикам
- Клиенты получают push от сервера

**Плюсы:**
- Все видят одно и то же время
- Сервер - единый источник правды

**Минусы:**
- Сложнее в реализации
- Нужна PubSub инфраструктура

**Пример из Phoenix:**
```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "timer:group_#{group_id}")
    schedule_tick()
  end
  {:ok, socket}
end

def handle_info(:tick, socket) do
  new_time = Timer.tick()
  Phoenix.PubSub.broadcast(
    MyApp.PubSub, 
    "timer:#{socket.assigns.group_id}", 
    {:time_updated, new_time}
  )
  schedule_tick()
  {:noreply, assign(socket, time: new_time)}
end

def handle_info({:time_updated, time}, socket) do
  {:noreply, assign(socket, time: time)}
end
```

---

## Вариант 3: Server-Sent Events (SSE)

**Идея:** HTTP-стрим от сервера к клиенту вместо WebSocket.

**Реализация:**
- Отдельный endpoint `/events`
- Сервер пишет в соединение каждую секунду
- Клиент слушает через EventSource API

**Плюсы:**
- Проще чем WebSocket для однонаправленного потока
- Автоматический reconnect
- Работает через HTTP (легче с прокси)

**Минусы:**
- Однонаправленный (только сервер → клиент)
- Не все браузеры (но все современные)

**Пример на Gleam:**
```gleam
fn handle_sse(request: Request(Connection)) -> Response(ResponseData) {
  mist.stream(
    request: request,
    initial: Nil,
    handler: fn(state, send) {
      process.sleep(1000)
      let time = get_current_time()
      send(json.to_string(time))
      mist.Continue(state)
    }
  )
}
```

---

## Вариант 4: WebSocket с server-initiated messages

**Идея:** Модифицировать текущий WebSocket handler чтобы сервер сам отправлял сообщения.

**Реализация:**
- В `init_tasks_socket` запускаем таймер
- Каждую секунду шлем сообщение в WebSocket connection
- Не ждем сообщений от клиента для обновления

**Плюсы:**
- Используем существующую инфраструктуру WebSocket
- Дуплексная связь

**Минусы:**
- Нужно модифицировать router.gleam
- Больше кода

**Где менять:** `src/router.gleam` - добавить таймер в `init_tasks_socket`

---

## Вариант 5: Lustre Effect.every (если появится)

**Идея:** Использовать встроенный эффект для периодических действий.

**Гипотетический API:**
```gleam
fn subscriptions(model: Model) -> Sub(Msg) {
  case has_active_tasks(model.tasks) {
    True -> effect.every(1000, Tick)
    False -> effect.none()
  }
}
```

**Плюсы:**
- Декларативно
- Lustre управляет подписками

**Минусы:**
- Не уверен что такой эффект есть в текущей версии

---

## Рекомендации

**Для текущего проекта (один пользователь):**
- Вариант 1 (Client-Side JS) - оптимально по соотношению простота/производительность
- Текущее решение (OTP actor) - работает, но создаёт лишнюю нагрузку на сервер

**Для многопользовательского таймера:**
- Вариант 2 (PubSub) - правильный выбор

**Для простоты реализации:**
- Вариант 4 (WebSocket server-initiated) - близко к текущей архитектуре

---

## Ссылки

- [Phoenix LiveView Timer Example](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
- [Distributed Timer with Phoenix LiveView](https://chrisodonnell.dev/posts/liveview/distributed-timer-with-phoenix-liveview/)
- [Building Real-Time Dashboards with Phoenix LiveView](https://dev.to/hexshift/building-real-time-dashboards-with-phoenix-liveview-33pl)
