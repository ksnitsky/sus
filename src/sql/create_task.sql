-- Create a new task with name and description
insert into tasks
  (name, description)
values
  ($1, $2)
returning
  id,
  name,
  description,
  status,
  time_spent_seconds,
  started_at,
  created_at
