#lang racket

(provide ROOT-DIR
         SRC-DIR
         TEMPLATES-DIR
         symbol->path
         path->symbol
         write-file)
(require racket/file)
(require html-writing)
(require hash-lambda)

(define ROOT-DIR (current-directory))
(define SRC-DIR (build-path ROOT-DIR (string->path "content")))
(define TEMPLATES-DIR (build-path ROOT-DIR (string->path "templates")))

(define (symbol->path sym)
  (string->path (symbol->string sym)))

(define (path->symbol path)
  (string->symbol (path->string path)))

(define (write-file sxml dest)
  (let ([port (open-output-file dest)])
    (write-html sxml port)
    (close-output-port port)))

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
