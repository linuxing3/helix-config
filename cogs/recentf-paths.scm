(require-builtin steel/process)
(require-builtin steel/ports)

(provide home-dir
         find-git-root-for
         recentf-storage-root-for
         recentf-default-file-for
         ensure-recentf-directory!)

(define (home-dir)
  (canonicalize-path "~"))

(define (find-git-root-for cwd)
  (with-handler
   (lambda (_err) #f)
   (let* ([cmd (command "git" (list "-C" cwd "rev-parse" "--show-toplevel"))]
          [_ (set-piped-stdout! cmd)]
          [child-result (spawn-process cmd)])
     (if (Err? child-result)
         #f
         (let* ([child (Ok->value child-result)]
                [stdout-result (wait->stdout child)])
           (if (Err? stdout-result)
               #f
               (let ([stdout (trim (Ok->value stdout-result))])
                 (if (equal? stdout "")
                     #f
                     stdout))))))))

(define (recentf-storage-root-for cwd)
  (or (find-git-root-for cwd)
      (home-dir)))

(define PATH-SEPARATOR "/")

(define (recentf-default-file-for cwd)
  (string-append (recentf-storage-root-for cwd)
                 PATH-SEPARATOR
                 ".helix"
                 PATH-SEPARATOR
                 "recent-files.txt"))

(define (ensure-recentf-directory! file-path)
  (let ([directory (parent-name file-path)])
    (unless (path-exists? directory)
      (create-directory! directory))))
