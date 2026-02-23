-- Start the timer for a task (set status to in_progress and record start time)
update tasks
set
  status = 'in_progress',
  started_at = $2
where
  id = $1
  and status in ('not_started', 'paused')
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
