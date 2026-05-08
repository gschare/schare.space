#lang racket

(provide ROOT-DIR
         SRC-DIR
         INTERMEDIATE-DIR
         TEMPLATES-DIR
         copy-to-intermediate
         symbol->path
         path->symbol
         write-file
         time-build-step
         last-runtime-seconds
         total-runtime-seconds
         format-runtime-seconds
         file-changed?
         sync-cache!)

(require racket/file)
(require html-writing)
(require hash-lambda)

(define ROOT-DIR (current-directory)) ; TODO: make this more general so it can work when the script is run from a different directory
(define SRC-DIR (build-path ROOT-DIR (string->path "content")))
(define INTERMEDIATE-DIR (build-path ROOT-DIR (string->path "temp")))
(define TEMPLATES-DIR (build-path ROOT-DIR (string->path "templates")))

(define (symbol->path sym)
  (string->path (symbol->string sym)))

(define (path->symbol path)
  (string->symbol (path->string path)))

(define (write-file sxml dest)
  (let ([port (open-output-file dest #:exists 'replace)])
    (write-html sxml port)
    (close-output-port port)))

(define (copy-to-intermediate)
  ; Only copy the files which are not already preprocessed!
  ; But since the only files already there are the preprocessed ones,
  ; we can just copy everything without overwriting.
  (current-directory SRC-DIR)

  (define (folder? path)
    (match (file-or-directory-type path)
      ['file #f]
      ['directory #t]
      [_ (error "invalid type ~a" path)]))

  (define (loop folders)
    (unless (set-empty? folders)
      (let* ([path (set-first folders)]
             [children (map (λ (p) (build-path path p)) (directory-list path))]
             [children-files (filter-not folder? children)]
             [children-folders (list->set (filter folder? children))])
        (for-each
          (λ (c)
            (let ([dest (build-path INTERMEDIATE-DIR c)])
              (unless (file-exists? dest) ; BUG: this is a bug. if you don't clear the temp/ folder it won't overwrite files that were there.
                (make-parent-directory* dest)
                (copy-file c dest #:exists-ok? #f))))
          children-files)
        (loop (set-union children-folders (set-remove folders path))))))

  (loop (set "."))
  (current-directory ROOT-DIR))

(define (pp-table ht)
  (printf "(\n")
  (hash-for-each
   ht
   (λ (k v)
     (apply/hash
      (λ (#:path path
          #:template template
          #:styles styles
          #:raw raw)
        (printf " (\e[1;34m:path\e[0m ") (write path)
        (if raw
            (begin (printf "\n  \x1b[1;32m:raw\x1b[0m ") (write raw))
            (begin (printf "\n  \x1b[1;36m:template\x1b[0m ") (write template)
                   (printf " \x1b[1;36m:styles\x1b[0m ") (write styles)))
        (printf "\n  )\n")
        ) v)))
  (printf "\n )"))

; Time tracking
(define last-runtime-seconds (make-parameter 0.0))
(define total-runtime-seconds (make-parameter 0.0))

(define-syntax-rule (time-build-step body ...)
  (let ([start (current-inexact-milliseconds)])
    (begin0
      (begin body ...)
      (last-runtime-seconds
        (/ (- (current-inexact-milliseconds) start)
           1000.0))
      (total-runtime-seconds
        (+ (last-runtime-seconds)
           (total-runtime-seconds))))))

(define (format-runtime-seconds . args)
  (let ([n (if (empty? args)
               (last-runtime-seconds)
               (apply + args))])
    (~r n #:precision '(= 3))))

; File change tracking
(require racket/runtime-path
         racket/hash)

(define-runtime-path cache-path
  ".mtime-cache.rktd")

(define mtime-cache
  (if (file-exists? cache-path)
      (call-with-input-file cache-path read)
      (hash)))

(define (save-cache!)
  (call-with-output-file
   cache-path
   #:exists 'truncate
   (lambda (out)
     (write mtime-cache out))))

(define (file-mtime path)
  (file-or-directory-modify-seconds path))

(define (file-changed? path)
  (define normalized (path->string (simplify-path path)))

  (cond
    [(not (file-exists? normalized))
     (set! mtime-cache
           (hash-set mtime-cache normalized #t))
     (save-cache!)
     #t] ; assume it changed if it doesn't exist
    [else
      (define current (file-mtime normalized))
      (define previous (hash-ref mtime-cache normalized #f))

      (define changed?
        (or (not previous)
            (> current previous)))

      (set! mtime-cache
            (hash-set mtime-cache normalized current))
  
      (if changed? (displayln (format "File ~a changed" normalized)) (void))

      changed?]))

(define (sync-cache!)
  (save-cache!))