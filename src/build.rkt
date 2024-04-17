; TODO: rewrite this in rust lol they have cool macros
; TODO: no, rewrite this in Haskell for the familiarity and type safety!
; TODO: no, do it in Ocaml! jane street uses sexprs!
; TODO: turn to the dark side; use Emacs Lisp as God intended
; TODO: no lol just refactor this still in racket using macros and DSLs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;       __                   ___       __              __      __              ;
;      /\ \              __ /\_ \     /\ \            /\ \    /\ \__           ;
;      \ \ \____  __  __/\_\\//\ \    \_\ \       _ __\ \ \/'\\ \ ,_\          ;
;       \ \ '__`\/\ \/\ \/\ \ \ \ \   /'_` \     /\`'__\ \ , < \ \ \/          ;
;        \ \ \L\ \ \ \_\ \ \ \ \_\ \_/\ \L\ \  __\ \ \/ \ \ \\`\\ \ \_         ;
;         \ \_,__/\ \____/\ \_\/\____\ \___,_\/\_\\ \_\  \ \_\ \_\ \__\        ;
;          \/___/  \/___/  \/_/\/____/\/__,_ /\/_/ \/_/   \/_/\/_/\/__/        ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Welcome to build.rkt.
; Author: Gregory Schare, March 2024.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#lang racket

(provide build)
(require html-parsing)
(require "rules.rkt")
(require "graph.rkt")
(require "io.rkt")
(require "hash.rkt")
(require "templates.rkt")

(define (lisp-keyword->racket-keyword sym)
  (let ((sym-string (symbol->string sym)))
    (cond
     [(char=? (string-ref sym-string 0) #\:)
      (string->keyword (substring sym-string 1))]
     [else sym])))

(define (build rules #:dest [dest "docs"] #:dry-run [dry-run #f])
  (let* (; Preprocess: convert ':kw to '#:kw
         [preprocessed (walk lisp-keyword->racket-keyword rules)]

         ; Convert rules to a hash table and check for duplicates
         [ht (rules->hash-table preprocessed)]

         ; Follow the DAG to assign each rule a template and list of styles.
         [style-assignments (resolve-graph (make-adjacency-list ht '#:styles ".") ".css")]
         [template-assignments
          (hash-map-update
           (resolve-graph (make-adjacency-list ht '#:template ".") ".sxml")
           (λ (v) (first v)))]
         [ht (hash-map-update
              ht
              (λ (v) (hash-set v '#:styles
                               (hash-ref style-assignments (hash-ref v '#:path)))))]

         ; Remove phonies
         [ht (hash-map-update
              (hash-filter-not
               ht
               (by-flag '#:phony))
              (λ (v) (hash-remove v '#:phony)))]

         ; Generate the full build plan by recursively getting the children
         ; of folders and applying their parent settings, unless already
         ; specified.
         ; Note: reads from disk!
         [ht (rules-closure ht)]

         ; Remove directories and all disabled rules from the ruleset, as we
         ; don't need them anymore.
         ; This give us our final build plan!
         [plan (hash-map-update
               (hash-filter-not
                ht
                (λ (v) (or ((by-flag '#:folder) v)
                           ((by-flag '#:disabled) v))))
               (λ (v) (hash-remove (hash-remove v '#:folder) '#:disabled)))]

         ; Load the templates recursively.
         ; Note: reads from disk!
         [templates (load-templates
                     (set->list (list->set
                                 (hash-values template-assignments))))]


         ; Build each non-raw file according to the plan.
         [files-sxml
          (hash-map/copy
           (hash-filter-not
            plan
            (λ (v) (hash-ref v '#:raw)))
           (λ (k v)
             (let ([template (hash-ref v '#:template)]
                   [content
                    (html->xexp (file->string
                      (build-path SRC-DIR
                                  (symbol->path (hash-ref v '#:path)))))]
                   [styles (stylelist->xexp (hash-ref v '#:styles))])
             (values
              k
              (apply-template
                (hash-ref templates template)
                content
                styles
                templates)))))]
         [raw-plan (hash-keys (hash-filter plan (λ (v) (hash-ref v '#:raw))))])
    (begin
      (when dry-run
        (display "This is a dry run. No files will be written.\n")
        (display "Files to be assembled according to a template:\n")
        (for-each (λ (x) (display "  ") (display x) (display "\n")) (hash-keys files-sxml))
        (display "Files to be copied:\n")
        (for-each (λ (x) (display "  ") (display x) (display "\n")) raw-plan)
        )

      (hash-for-each
       files-sxml
       (λ (k v)
         (let* ([path (symbol->path k)]
                [dest (build-path dest path)])
           (unless dry-run
            (make-parent-directory* dest)
            (write-file v dest))
           )))

      (for-each
       (λ (x)
         (let* ([path (symbol->path x)]
                [src (build-path SRC-DIR path)]
                [dest (build-path dest path)])
           (unless dry-run
            (make-parent-directory* dest)
            (copy-file src dest))
           ))
       raw-plan)
    )))
