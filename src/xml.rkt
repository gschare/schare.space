#lang racket

(provide xml)
(require racket/system)
(require "io.rkt")

(define (xml pathsym #:base [base SRC-DIR])
  ; Given a path symbol (e.g. 'garden/myfile.xml) specifying an XML file,
  ; generate the standalone html of the file using the corresponding XSLT file
  ; (e.g. 'garden/myfile.xslt) and write that to file in the intermediate
  ; directory, with an html extension. This will overwrite the existing
  ; one.
  ;
  ; Optionally accepts a base prefix to prepend to the path symbol to form the full path.
  ; Defaults to the SRC-DIR.
  ;
  ; Returns the symbol of the destination path.
  ;
  ; NOTE: be careful! You may have other rules that affect the .xml sources.
  (let* ([src-path (build-path base (symbol->path pathsym))]
         [xslt-path (path-replace-extension src-path ".xslt")]
         [dest-path (path-replace-extension (build-path INTERMEDIATE-DIR (symbol->path pathsym)) ".html")]
         [dest-sym (path->symbol (path-replace-extension (symbol->path pathsym) ".html"))])
    (system (string-append "xsltproc -o " (path->string dest-path) " " (path->string xslt-path) " " (path->string src-path)))
    dest-sym))
