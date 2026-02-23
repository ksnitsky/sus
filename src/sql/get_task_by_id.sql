-- Get a single task by its ID
select
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
from
  tasks
where
  id = $1
