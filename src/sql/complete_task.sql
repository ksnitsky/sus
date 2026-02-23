-- Complete a task (stop timer if running and set status to completed)
update tasks
set
  status = 'completed',
  time_spent_seconds = time_spent_seconds + coalesce(
    extract(epoch from ($2::timestamp - started_at))::integer,
    0
  ),
  started_at = null
where
  id = $1
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
