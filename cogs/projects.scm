(require "helix/editor.scm")
(require "helix/misc.scm")
(require (prefix-in helix. "helix/commands.scm"))
(require "cogs/picker.scm")

(provide project-switch
         project-add
         project-add-current
         project-delete
         project-discover)

;; Capture helix config dir at load time before any :cd changes it
(define *helix-config-dir* (current-directory))

(define PROJECTS-FILE
  (let ([dir (string-append *helix-config-dir* "/.helix")])
    (unless (path-exists? dir)
      (create-directory! dir))
    (string-append dir "/projects.txt")))

(define (read-projects)
  (if (path-exists? PROJECTS-FILE)
      (let ([content (call-with-input-file PROJECTS-FILE
                       (lambda (f) (read-port-to-string f)))])
        (if (equal? content "")
            '()
            (filter (lambda (s) (not (equal? s "")))
                    (split-many content "\n"))))
      '()))

(define (write-projects! projects)
  (call-with-port (open-output-file PROJECTS-FILE #:exists 'truncate)
                  (lambda (out)
                    (for-each (lambda (p)
                                (display p out)
                                (newline out))
                              projects))))

(define (project-switch)
  (define projects (read-projects))
  (if (null? projects)
      (set-error! "No projects. Use :project-add <path> or :project-add-current")
      (push-component!
       (picker-selection
        projects
        (lambda (selected)
          (helix.change-current-directory selected)
          (set-status! (string-append "Switched to: " selected)))
        #:highlight-prefix "> "
        #:title "Switch project"))))

(define project-add
  (lambda args
    (if (null? args)
        (set-error! "Usage: :project-add <path>")
        (let* ([path (car args)]
               [projects (read-projects)])
          (if (member path projects)
              (set-warning! (string-append "Already exists: " path))
              (begin
                (write-projects! (append projects (list path)))
                (set-status! (string-append "Added project: " path))))))))

(define (project-add-current)
  (let* ([cwd (current-directory)]
         [projects (read-projects)])
    (if (member cwd projects)
        (set-warning! (string-append "Already exists: " cwd))
        (begin
          (write-projects! (append projects (list cwd)))
          (set-status! (string-append "Added: " cwd))))))

(define (project-delete)
  (define projects (read-projects))
  (if (null? projects)
      (set-error! "No projects to delete")
      (push-component!
       (picker-selection
        projects
        (lambda (selected)
          (write-projects! (filter (lambda (p) (not (equal? p selected))) projects))
          (set-status! (string-append "Removed: " selected)))
        #:highlight-prefix "x "
        #:title "Delete project"))))

(define (find-git-subdirs parent)
  (filter (lambda (sub) (path-exists? (string-append sub "/.git")))
          (filter is-dir? (read-dir parent))))

(define (discover-in parent)
  (if (not (is-dir? parent))
      (set-error! (string-append "Not a directory: " parent))
      (let* ([git-dirs (find-git-subdirs parent)]
             [existing (read-projects)]
             [new-dirs (filter (lambda (d) (not (member d existing))) git-dirs)])
        (if (null? new-dirs)
            (set-status! "No new git projects found")
            (begin
              (write-projects! (append existing new-dirs))
              (set-status! (string-append "Added "
                                          (number->string (length new-dirs))
                                          " projects from "
                                          parent)))))))

(define (project-discover)
  (push-component!
   (prompt
    (string-append "Discover in [" (current-directory) "]: ")
    (lambda (input)
      (define parent (if (equal? input "") (current-directory) input))
      (discover-in parent)))))
