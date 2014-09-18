(in-package :turtl-core)

(defun enqueue (job)
  "Enqueue a new job."
  (let ((data (hash ("grabbed" nil)
                    ("data" job))))
    (db-save "queue" data)))

(defun dequeue ()
  "Grab the next job."
  (sqlite:execute-non-query (dbc *db*) "BEGIN TRANSACTION")
  (let* ((ts (- (timestamp) 30))
         (sql "SELECT
                   *
               FROM
                   queue
               WHERE
                   grabbed IS NULL OR
                   grabbed < ?
               ORDER BY
                   id ASC
               LIMIT 1 ")
         (job (car (sql-to-objects (dbc *db*) sql ts)))
         (ts (timestamp)))
    (when job
      (let ((id (gethash "id" job)))
        (sqlite:execute-non-query (dbc *db*)
                                  "UPDATE queue SET grabbed = ? WHERE id = ?"
                                  ts 
                                  id)
        job))
    (sqlite:execute-non-query (dbc *db*) "COMMIT TRANSACTION")
    job))

(defun complete (job)
  "Mark a job as complete (delete it)."
  (let ((id (if (hash-table-p job)
                (gethash "id" job)
                job)))
    (sqlite:execute-non-query (dbc *db*)
                              "DELETE FROM queue WHERE id = ?"
                              id)))

