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
  (if (symbol? sym)
      (let ((sym-string (symbol->string sym)))
        (cond
         [(char=? (string-ref sym-string 0) #\:)
          (string->keyword (substring sym-string 1))]
         [else sym]))
      sym))

(define (build rules #:dest [dest "docs"] #:dry-run [dry-run #f] #:silent [silent #f] #:verbose [verbose #f])
  (define (displayln-unless-silent . args) (unless silent (apply displayln args)))
  (define (displayln-if-verbose . args) (if verbose (apply displayln args) (void)))
  (define (display-unless-silent . args) (unless silent (apply display args)))
  (define (display-if-verbose . args) (if verbose (apply display args) (void)))
  (define (display-runtime-seconds . args) (displayln-unless-silent (format "~as" (apply format-runtime-seconds args))))
  (displayln-unless-silent (format "Files to be written to folder: ~a." dest))
  (let* (; Preprocess: convert ':kw to '#:kw
         [_ (display-unless-silent "Rules: preprocess....")]
         [preprocessed (time-build-step (walk lisp-keyword->racket-keyword rules))]
         [_ (display-runtime-seconds)]

         ; Convert rules to a hash table and check for duplicates
         [_ (display-unless-silent "Rules: duplicates check....")]
         [ht (time-build-step (rules->hash-table preprocessed))]
         [_ (display-runtime-seconds)]

         ; Follow the DAG to assign each rule a template and list of styles.
         [_ (display-unless-silent "Rules: assign templates and styles....")]
         [style-assignments (time-build-step (resolve-graph (make-adjacency-list ht '#:styles ".") ".css"))]
         [_t1 (last-runtime-seconds)]
         [template-assignments (time-build-step
          (hash-map-update
           (resolve-graph (make-adjacency-list ht '#:template ".") ".sxml")
           (λ (v) (first v))))]
         [_t2 (last-runtime-seconds)]
         [ht (time-build-step (hash-map-update
              ht
              (λ (v) (hash-set v '#:styles
                               (hash-ref style-assignments (hash-ref v '#:path))))))]
         [_t3 (last-runtime-seconds)]
         [_ (display-runtime-seconds _t1 _t2 _t3)]

         ; Remove phonies
         [_ (display-unless-silent "Rules: remove phonies....")]
         [ht (hash-map-update
              (hash-filter-not
               ht
               (by-flag '#:phony))
              (λ (v) (hash-remove v '#:phony)))]
         [_ (display-runtime-seconds)]

         ; Copy non-preprocessed files to assemble to the intermediate
         ; directory, where preprocessed files are.
         ; (This is to keep the SRC dir clean of generated files.)
         ; Note: reads from disk!
         ; Note: writes to disk! (but only to intermediate directory)
         [_ (displayln-unless-silent "Copy non-preprocessed files to intermediate area....")]
         [_ (time-build-step (copy-to-intermediate))]
         [_ (display-runtime-seconds)]

         ; Generate the full build plan by recursively getting the children
         ; of folders and applying their parent settings, unless already
         ; specified.
         ; Note: reads from disk!
         [_ (display-unless-silent "Generate build plan....")]
         [ht (time-build-step (rules-closure ht))]
         [_ (display-runtime-seconds)]

         ; Remove directories and all disabled rules from the ruleset, as we
         ; don't need them anymore.
         ; This give us our final build plan!
         [_ (displayln-unless-silent "Prune build plan....")]
         [plan (time-build-step (hash-map-update
               (hash-filter
                (hash-filter-not
                 ht
                 (λ (v) (or ((by-flag '#:folder) v)
                            ((by-flag '#:disabled) v))))
                (λ (v) (or (let ((pre-src (hash-ref v '#:preprocessed)))
                             (cond
                              [(symbol? pre-src) ; we have a source to check for instead of the generated shit
                               (file-changed? (build-path SRC-DIR (symbol->path pre-src)))]
                              [pre-src #t] ; all we know is it was preprocessed, so assume it changed
                              [else (file-changed? (build-path SRC-DIR (symbol->path (hash-ref v '#:path))))]))
                           (file-changed? (build-path TEMPLATES-DIR (symbol->path (hash-ref v '#:template))))
                           (file-changed? "site.rkt")
                           (foldr (λ (s b) (or (file-changed? (build-path SRC-DIR (symbol->path s))) b)) #f (hash-ref v '#:styles)))))
               (λ (v) (hash-remove (hash-remove v '#:folder) '#:disabled))))]
         [_ (display-runtime-seconds)]
         [_ (if verbose
                (hash-map-update
                 (hash-filter
                  ht
                  (λ (v) ((by-flag '#:disabled) v)))
                 (λ (v) (displayln-if-verbose (format "Disable ~a" (hash-ref v '#:path)))))
                (void))]

         ; Load the templates recursively.
         ; Note: reads from disk!
         [_ (display-unless-silent "Load templates....")]
         [templates (time-build-step (load-templates
                     (set->list (list->set
                                 (hash-values template-assignments)))))]
         [_ (display-runtime-seconds)]

         ; Build each non-raw file according to the plan.
         ; Only files ending in `.html` will be built.
         [_ (display-unless-silent "Assemble non-raw files....")]
         [files-sxml
          (time-build-step (hash-map/copy
           (hash-filter
            plan
            (λ (v) (and
                    (string-suffix?
                     (symbol->string (hash-ref v '#:path))
                     ".html")
                    (not (hash-ref v '#:raw)))))
           (λ (k v)
             (let ([template (hash-ref v '#:template)]
                   [content
                    (html->xexp (file->string
                      (build-path INTERMEDIATE-DIR
                                  (symbol->path (hash-ref v '#:path)))))]
                   [styles (stylelist->xexp (hash-ref v '#:styles))])
             (displayln-if-verbose (format "Plan ~a with template ~a and styles ~a" (hash-ref v '#:path) template (hash-ref v '#:styles)))
             (values
              k
              (apply-template
                (hash-ref templates template)
                content
                styles
                templates))))))]
         [_t1 (last-runtime-seconds)]
         [raw-plan (time-build-step (hash-keys (hash-filter plan (λ (v) (displayln-if-verbose (format "Raw plan ~a" (hash-ref v '#:path))) (hash-ref v '#:raw)))))]
         [_t2 (last-runtime-seconds)]
         [_ (display-runtime-seconds _t1 _t2)])
    (begin
      (when dry-run
        (display "This is a dry run. No files will be written.\n")
        (display "Files to be assembled according to a template:\n")
        (for-each (λ (x) (display "  ") (display x) (display "\n")) (hash-keys files-sxml))
        (display "Files to be copied:\n")
        (for-each (λ (x) (display "  ") (display x) (display "\n")) raw-plan)
        )

      (displayln-unless-silent "Writing files....")
      (time-build-step (hash-for-each
       files-sxml
       (λ (k v)
         (let* ([path (symbol->path k)]
                [dest (build-path dest path)])
           (displayln-if-verbose (format "Writing ~a -> ~a" path dest))
           (unless dry-run
            (make-parent-directory* dest)
            (write-file v dest))
           ))))
      (displayln-unless-silent (if dry-run "Dry run: no files written." (format "~a files written." (hash-count files-sxml))))
      (display-runtime-seconds)

      (displayln-unless-silent "Copying raw files....")
      (time-build-step (for-each
       (λ (x)
         (let* ([path (symbol->path x)]
                [src (build-path SRC-DIR path)]
                [dest (build-path dest path)])
           (displayln-if-verbose (format "Writing raw ~a -> ~a" path dest))
           (unless dry-run
            (make-parent-directory* dest)
            (copy-file src dest #:exists-ok? #t))
           ))
       raw-plan))
      (displayln-unless-silent (if dry-run "Dry run: no raw files copied." (format "~a raw files copied." (length raw-plan))))
      (display-runtime-seconds)

      (displayln-unless-silent (format "Total runtime: ~a seconds." (total-runtime-seconds)))

      (sync-cache!)
    )))