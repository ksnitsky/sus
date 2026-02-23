-- Stop the timer for a task (pause it and accumulate elapsed time)
update tasks
set
  status = 'paused',
  time_spent_seconds = time_spent_seconds + $2,
  started_at = null
where
  id = $1
  and status = 'in_progress'
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
