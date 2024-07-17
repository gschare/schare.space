#lang racket

(provide md)
(require racket/system)
(require "io.rkt")

(define (md pathsym)
  ; Given a path symbol (e.g. 'garden/myfile.md) specifying a markdown file,
  ; generate the standalone html of the file and write that to file in the
  ; same directory as the original, with an html extension. This will overwrite
  ; the existing one.
  ;
  ; Returns the symbol of the destination path.
  (let* ([src-path (build-path SRC-DIR (symbol->path pathsym))]
         [dest-path (path-replace-extension src-path ".html")]
         [dest-sym (path->symbol (path-replace-extension (symbol->path pathsym) ".html"))])
    (system (string-append "pandoc --mathjax -f markdown -t html -o " (path->string dest-path) " " (path->string src-path)))
    dest-sym))
