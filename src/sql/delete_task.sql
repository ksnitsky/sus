-- Delete a task by its ID
delete from tasks
where id = $1
