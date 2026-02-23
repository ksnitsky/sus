-- Get all tasks ordered by creation date (newest first)
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
order by
  created_at desc
