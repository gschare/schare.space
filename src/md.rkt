#lang racket

(provide md
         md*
         )
(require racket/system)
(require "io.rkt")

(define (md pathsym #:base [base SRC-DIR])
  ; Given a path symbol (e.g. 'garden/myfile.md) specifying a markdown file,
  ; generate the standalone html of the file and write that to file in the
  ; intermediate directory, with an html extension. This will overwrite
  ; the existing one.
  ;
  ; Optionally accepts a base prefix to prepend to the path symbol to form the full path.
  ; Defaults to the SRC-DIR.
  ;
  ; Returns the symbol of the destination path.
  ;
  ; NOTE: be careful! You may have other rules that affect the .md sources.
  (let* ([path (symbol->path pathsym)]
         [src-path (build-path base path)]
         [rel-path (if (absolute-path? src-path)
                       (find-relative-path SRC-DIR src-path)
                       src-path)]
         [dest-path (path-replace-extension (build-path INTERMEDIATE-DIR rel-path) ".html")]
         [dest-sym (path->symbol (path-replace-extension rel-path ".html"))])
    (make-parent-directory* dest-path)
    (system (string-append "pandoc --mathjax --section-divs -f markdown -t html -o " (path->string dest-path) " " (path->string src-path)))
    dest-sym))

(define (md* folder-path-sym #:base [base SRC-DIR] #:recursive [recursive #f])
  ; Same as `md`, but for folders.
  ; Generates the .html files for every .md in the directory.
  ; Non-recursive by default.
  ;
  ; Optionally accepts a base prefix to prepend to the path symbol to form the full path.
  ; Defaults to the SRC-DIR.
  ;
  ; Returns the folder symbol path.
  ;
  ; Use it like so: `:folders (:path ,(md* 'garden))`
  ; I.e. intercept a folder rule to generate HTML files for the Markdown sources
  ; in that folder, so that the generated HTML gets included in the rule.
  ; This is the only real use case for this function.
  ;
  ; NOTE: be careful! You may have other rules that behave unexpectedly around
  ; the .md sources or the generated .html files in temp/, especially when
  ; performed recursively.
  (let* ([dir-path (build-path base (symbol->path folder-path-sym))]
         [paths (directory-list dir-path)])

    (define (folder? path)
      (match (file-or-directory-type (build-path dir-path path))
        ['file #f]
        ['directory #t]
        [_ (error "invalid type ~a" path)]))

    (map (lambda (p) (md (path->symbol p) #:base dir-path))
         (filter (lambda (p) (path-has-extension? p #".md"))
                 (filter-not folder? paths)))
    (if recursive
      (map (lambda (d) (md* (path->symbol d) #:base dir-path #:recursive #t))
           (filter folder?  paths))
      (void)))

  folder-path-sym)
