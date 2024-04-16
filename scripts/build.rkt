#lang racket

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
;; How this build script works
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Steps:
;   1. Read the config file which contains rules about how to assemble files.
;   2. Parse the config and validate it, possibly throwing errors.
;   3. Resolve the rules and determine a file build order.
;   4. Load each file one by one, assemble them, and write them to the output
;      folder.
;
; This means the file basically has 5 parts:
;   1. Parse the rules from s-exprs into a graph.
;   2. Convert this graph into a stylesheet inheritance DAG by condensing
;      strongly connected components.
;   3. Use the DAG to resolve the inheritance and get a list of all files.
;   4. Process each file in the list by parsing the HTML of the layout file,
;      assembling it, and writing it to disk
;
;; Config format
;;;;;;;;;;;;;;;;
;
; We use a rule-based format for specifying the config. It is given as an
; s-expression (with keywords), here denoted partly by example, partly by
; grammar.
;
;     '(:defaults
;        (:template <PATH>                ; relative to templates/
;         :styles (<PATH> ...))           ; relative to css/
;       :files
;        ((:path <PATH>                   ; relative to src/
;          :template <TEMPLATE>
;          :styles (<STYLE> ...))
;         ...)
;       :folders
;        ((:path <PATH>                   ; relative to src/
;          :template <TEMPLATE>
;          :styles (<STYLE> ...))
;         ...)
;       :phony
;        ((:path <PATH>                   ; this can be anything
;          :template <TEMPLATE>
;          :styles (<STYLE> ...))
;         ...)
;       :raw
;        (:files (<PATH> ...)
;         :folders (<PATH> ...)
;         )
;       :disabled
;        (:files (<PATH> ...)
;         :folders (<PATH> ...)
;         )
;       )
;
; The PATH of a folder or file rule is considered its name and unique identifier
; as a rule. It is invalid to specify two or more rules with the same name; we
; check for duplicates and reject rulesets containing duplicate rules.
;
; For a given rule (call it `R`), <STYLE> may be provided as a path to a CSS
; stylesheet (determined by whether the token ends with `.css`), or as the name
; of another rule. If given as the name of another rule `S`, `R` inherits all
; the styles from `S`.
;
; This allows for an arbitrary directed graph where an edge (u,v) means
; "u inherits from v". Cycles are possible, but invalid; we reject graphs with
; cycles in them.
;
; Technically it would be fine to have cycles, because nodes in the same
; strongly connected component share the same set of styles. We could use
; Kosaraju's algorithm to detect SCCs and convert the graph to a DAG, but then
; it would be difficult to ensure stylesheets cascade properly. Instead,
; we require the user to provide a DAG and then we assign a deterministic
; stylesheet order on a per-rule basis by traversing the DAG.
;
; Note that unexpected cascading can still happen when styles are listed in
; certain orders. Consider rules u,v,w and stylesheets x,y, with edges
; (u,v), (u,w), (v,w), (v,x), (w,x), (w,y). If v has [x,w] as its style list and
; w has [y,x] as its list, then it will resolve to v=[x,y], w=[y,x], and
; u=[x,y]. But if v has [w,x], then it will resolve to v=[y,x], w=[y,x] and
; u=[y,x]. Be careful of this, and try to avoid redundancy. In most cases it
; would be preferable to simply have v inherit w, unless we really want to swap
; the order of x and y for v and u but not for w.
;
; <TEMPLATE> can similarly point to either an actual template file (ending in
; `.html`) or another rule. It is possible to form cycles here, too, but it is
; invalid to do so (we check for cycles and reject graphs that contain them).
;
; Templates must end in .sxml. Stylesheets must end in .css. HTML
; fragments/source files have no requirements for extensions, but it helps to
; end them with .html (to avoid conflicts or confusion). Folders should not end
; in '/', and similarly must not conflict. This is subject to change.
;
; For files, folders, and phonies, the following keywords are optional:
;   :template
;   :styles
;
; If optional keywords are left off, or left blank, the corresponding
; default is used.
;
; When a folder rule is provided, its rules automatically apply to everything
; inside it recursively. If a subfolder or file within the folder (at any depth)
; has its own rule, it does not inherit (but you can explicitly ask it to
; inherit by adding the name of its parent rule).
;
; The :raw keyword specifies which files and folders should be copied to the
; output directory without any processing. As usual, subfolders and files may
; overwrite the recursive default, but duplicates of any PATHs are invalid
;
; The :disabled keyword is similar, but instructs the build system to skip the
; given files and folders. Unlike the other rules, :disabled is allowed
; to overwrite other rules with the same name.
;
; TODO: add a markdown flag
; TODO: add a setting for custom build commands (like a makefile)
; TODO: add nice syntax for arbitrary arguments passed to template
;
;; Template format
;;;;;;;;;;;;;;;;;;
;
; This is actually very simple. A template (or layout) is a HTML
; file containing some special tags that indicate how to assemble a final HTML
; file using fragments of HTML from other files given as input or specified in
; the template.
;
; Currently, no advanced templating features are supported, but these can be
; added later on as extensions to the templating language syntax.
;
; The special tags are as follows:
;
;   <insert expr="EXPR">
;   At assembly time, this is replaced by the DOM nodes that result from
;   evaluating EXPR in the context of the available variable bindings.
;   These nodes may be siblings; they are given as a list. No
;   checking is performed; this may produce invalid HTML.
;   
;   <template target="NAME">
;   At assembly time, this is replaced by the template called NAME. Then, assembly
;   instruction tags in that template are resolved until no more instruction
;   tags can be found. Hence this is recursive. Cycles will result in infinite
;   loops, so don't do that. Arguments are forwarded, not shadowed, so the user
;   must provided all of the arguments for the entire tree of templates upfront.
;
; Two arguments are passed by default: `content` and `styles`. The
; `content` is the HTML fragment being processed, and the `styles` is a
; list of `<link>` tags to the stylesheets specified in the rules for that file.
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require hash-lambda) ; TODO: avoid using this library
(require racket/hash)
(require racket/file)
;(require html-template)
(require html-parsing)
(require html-writing)
(require sxml)

(define ROOT-DIR (current-directory))
(define SRC-DIR (string->path "src"))
(define DEST-DIR (string->path "docs2"))
(define TEMPLATES-DIR (string->path "templates"))
(define CSS-DIR (string->path "css"))
(define CONFIG-DIR (string->path "config"))
; TODO: pass all of these in the config as well

(define-namespace-anchor nsa)
(define ns (namespace-anchor->namespace nsa))

(define (walk f tree)
  (cond
   [(empty? tree) tree]
   [(list? (first tree)) (cons (walk f (first tree)) (walk f (rest tree)))]
   [else (cons (f (first tree)) (walk f (rest tree)))]))

(define (lisp-keyword->racket-keyword sym)
  (let ((sym-string (symbol->string sym)))
    (cond
     [(char=? (string-ref sym-string 0) #\:)
      (string->keyword (substring sym-string 1))]
     [else sym])))

(define (symbol->path sym)
  (string->path (symbol->string sym)))

(define (path->symbol path)
  (string->symbol (path->string path)))

(define (hash-filter ht pred)
  (foldl (λ (x acc)
           (let ([k (car x)]
                 [v (cdr x)])
            (if (pred v)
                (hash-set acc k v)
                acc)))
         (hash)
         (hash->list ht)))

(define (hash-filter-not ht pred)
  (hash-filter ht (λ (x) (not (pred x)))))

(define (by-flag flag)
  (lambda (ht-rule)
    (hash-ref ht-rule flag)))

(define (hash-map-update ht updater)
  (hash-map/copy ht (λ (k v) (values k (updater v)))))

(define (config->hash-table config)
  ; Parses and combines all the different rules into one big hash table with all
  ; the info, and checks for duplicates.
  ;
  ; You may regard this function as more or less a definition of the
  ; config schema and the default behaviors.

  (apply/hash
   (λ (#:defaults defaults
       #:files [files '()]
       #:folders [folders '()]
       #:phony [phony '()]
       #:raw [raw '(#:files () #:folders ())]
       #:disabled [disabled '(#:files () #:folders ())])

     (define-values (default-template default-styles)
                    (apply/hash (λ (#:template t #:styles s) (values t s))
                                (apply hash defaults)))

     (define names (mutable-set))

     (define (add-to-table row)
       (let
           ([make-row
             ; do we really gain anything by embedding the schema in function
             ; arguments like this?
             ; how busted do we think it is to use this
             ; `(apply/hash f (apply hash x))` pattern for passing the config
             ; as arguments to a function to parse it automatically?
             (λ (#:path path
                 #:template [template default-template]
                 #:styles [styles default-styles]
                 #:folder [folder #f]
                 #:phony [phony #f]
                 #:raw [raw #f]
                 #:disabled [disabled #f])
               (if (and (set-member? names path) (not disabled))
                   (error (format "duplicate identifier ~a" path))
                   (set-add! names path))
               (hash '#:path path
                     '#:template template
                     '#:styles styles
                     '#:folder folder
                     '#:phony phony
                     '#:raw raw
                     '#:disabled disabled))])
           ; TODO: refactor this function to just map over hash-update with a
           ; default.
           ; in fact that should work in general throughout this file to replace
           ; the library that provides apply/hash
        (apply/hash make-row (apply hash row))))

     (let*
         ([ht-raw (apply hash raw)]
          [ht-disabled (apply hash disabled)]
          [list-of-items
           (append 
            ; TODO: clean this up
            (map add-to-table files)
            (map (λ (x) (add-to-table (append '(#:folder #t) x)))
                 folders)
            (map (λ (x) (add-to-table (append '(#:phony #t) x)))
                phony)
            (map (λ (x) (add-to-table (list '#:path x '#:raw #t)))
                 (hash-ref ht-raw '#:files))
            (map (λ (x) (add-to-table (list '#:path x '#:disabled #t)))
                 (hash-ref ht-disabled '#:files))
            (map (λ (x) (add-to-table (list '#:path x
                                            '#:raw #t
                                            '#:folder #t)))
                 (hash-ref ht-raw '#:folders))
            (map (λ (x) (add-to-table (list '#:path x
                                            '#:disabled #t
                                            '#:folder #t)))
                 (hash-ref ht-disabled '#:folders))
            )])

       (foldl (λ (x acc)
                ; TODO: improve this logic
                (let ([name (hash-ref x '#:path)])
                  (if (hash-has-key? acc name)
                      (if (hash-ref x '#:disabled)
                          (hash-set acc name
                                    (hash-set (hash-ref acc name)
                                              '#:disabled #t))
                          (if (hash-ref (hash-ref acc name) '#:disabled)
                              (hash-set acc name
                                        (hash-set x '#:disabled #t))
                              (error "unreachable")))
                      (hash-set acc name x))))
              (hash)
              list-of-items)
       )

   ) (apply hash config)))

(define (check-exists table)
  (define (check #:path path
                 #:folder folder?
                 #:template template
                 #:styles styles
                 #:raw _
                 #:disabled disabled?)
    (let ([path (build-path SRC-DIR (string->path (symbol->string path)))]
          [template (build-path TEMPLATES-DIR
                                (string->path (symbol->string template)))]
          [styles (map (λ (s) (build-path
                               CSS-DIR
                               (string->path (symbol->string s)))) styles)])
      (if disabled?
          (void)
          (begin
            (if folder?
                (directory-exists? path)
                (file-exists? path))
            (file-exists? template)
            (for-each file-exists? styles)
            ))))
  (for-each (λ (r) (apply/hash check r)) (hash-values table)))

(define (check-for-disabled-references table)
  ; It is invalid to point to a disabled rule.
  ; This is because you may want to use disabling a rule as a kind of "comment".
  ; When a rule is disabled, some of its static checks are skipped, but
  ; this means we have to reject references to disabled rules lest the checks
  ; on enabled rules become unsound via propagation.
  (define (check key)
    (if (hash-ref (hash-ref table key) '#:disabled)
        (error "cannot reference disabled rule ~a" key
              ". Try a phony rule instead.")
        (void)))

  (define (has-extension? s)
    (let ([str (symbol->string s)])
      (or (string-suffix? s ".css")
          (string-suffix? s ".xml"))))

  (define (check-edges e)
    (cond
     [(list? e)
      (map check (filter-not has-extension? e))]
     [(symbol? e) (if (has-extension? e)
                      (void)
                      (check e))]))

  (hash-for-each
   table
   (λ (k v)
     (check-edges (hash-ref v '#:template))
     (check-edges (hash-ref v '#:styles)))))


(define (make-adjacency-list table field extension)
  (define (has-extension? s)
    (string-suffix? (symbol->string s) extension))

  (define (get-edges v)
    (let ([edges (hash-ref v field)])
      (cond
       [(list? edges) (filter-not has-extension? edges)]
       [(symbol? edges)
        (if (has-extension? edges)
            (list)
            (list edges))]
       [else (error "invalid field type in ~a" field)])))

  ; This could use hash-map-update if we allow it to decide mutability or just
  ; hard-code it to produce immutable hash tables
  (make-immutable-hash
   (hash-map
    table
    (λ (k v) (cons k (get-edges v))))))

(define (check-for-cycles adj-list)
  (define finished (mutable-set))
  (define visited (mutable-set))

  (define (dfs vertex)
    (cond
     [(set-member? finished vertex) (void)]
     [(set-member? visited vertex) (error "cycle found at ~a" vertex)]
     [else (begin (set-add! visited vertex)
                  (for-each dfs (hash-ref adj-list vertex))
                  (set-add! finished vertex))]))

  (for-each dfs (hash-keys adj-list)))

(define (resolve-graph adj-list extension)
  ; "Make a mess, then clean it up." ~Stephen A. Edwards
  ; Run a DFS on every node to get all the styles.
  ; Append together each sub-result.
  ; Remove duplicates following the first instance of every stylesheet.
  ;
  ; TODO: find a more robust solution than just checking the extension.
  ; I.e. have a proper notion of leaf nodes
  (define (dfs vertex)
    (cond
     [(string-suffix? (symbol->string vertex) extension)
      (list vertex)]
     [else (append-map dfs (hash-ref adj-list vertex))]))

  ; TODO: tweak this so it doesn't repeat a ton of work
  (hash-map-update
   adj-list
   (λ (edges) (remove-duplicates (append-map dfs edges))))
  )

(define (stylelist->xexp stylelist)
  (map
   (λ (s)
     (let ([href (string-append "/"
                                (path->string CSS-DIR)
                                "/"
                                (symbol->string s))])
       `(link (@ (rel "stylesheet")
                 (type "text/css")
                 (href ,href)))))
  stylelist))

;; I/O
(define (read-config)
  '(:defaults (:template default.sxml
               :styles (default.css))
    :files ((:path new.html
             :template new.sxml
             :styles (default.css new.css))
            (:path index.html)
            (:path now.html)
            (:path cv.html) ;:styles (new.html))
            (:path 404.html) ;:styles (cv.html))
            (:path tidings/index.html)
            )
     :folders ((:path garden
                :template garden.sxml
                :styles (default.css garden.css))
               (:path tidings
                :template blog.sxml
                :styles (default.css tidings.css))
               )
     :phony ()
     :raw (:files (assets/cv.pdf
                   assets/hoogleplus-review.pdf
                   assets/semgus-review.pdf)
           :folders (writ)
           )
     :disabled (:files ()
                :folders ()
                :folders ()
                )
     )
  )

(define (rules-closure rules-table)
  ; We have to do this quite carefully.
  ;
  ; We create a set containing every enabled directory in the ruleset.
  ; While the set is not empty, pop the first item, generate a list of its
  ; children, remove the ones that already have a rule in place, apply the
  ; parent's settings to the remaining ones, add the files to a hash table, and
  ; add the directories to the set.
  ;
  ; Once the set is empty, union the child hash table with the ruleset hash
  ; table.

  (define (rule-exists? path)
    (hash-has-key? rules-table (path->symbol path)))

  (define (folder? path)
    (match (file-or-directory-type path)
      ['file #f]
      ['directory #t]
      [_ (error "invalid type ~a" path)]))

  (define (pathlist->hash pathlist parent-hash #:folder folder)
    ; It actually doesn't matter whether or not we assign '#:folder
    ; correctly at this point since the last time it is queried
    ; is at the start of rules-closure to create the folders set.
    ; But, for good hygiene, we require it.
    (make-immutable-hash
     (map (λ (path)
            (let ([sym (path->symbol path)])
              (cons sym
                    (hash-set* parent-hash '#:path sym '#:folder folder))))
          pathlist)))

  ; TODO refactor as named let
  (let ([folders
         (hash-filter
          rules-table
          (λ (v) (and (hash-ref v '#:folder)
                      (not (hash-ref v '#:disabled)))))]
        [new-files (hash)])
    (define (loop folders new-files)
      (cond
       [(hash-empty? folders) new-files]
       [else
        (let* ([key (first (hash-keys folders))]
               [value (hash-ref folders key)]
               [path (symbol->path key)]
               [children
                (filter-not
                 rule-exists? ; Note that this includes disabled rules, so there
                              ; is no need to additionally filter out disabled.
                 (map
                  (λ (p) (build-path path p))
                  (directory-list path)))]
               [children-files (pathlist->hash
                                (filter-not folder? children)
                                value #:folder #f)]
               [children-folders (pathlist->hash
                                (filter folder? children)
                                value #:folder #t)])
          (loop (hash-union children-folders (hash-remove folders key))
                (hash-union new-files children-files)))]))

    (current-directory SRC-DIR)
    (define result (hash-union rules-table (loop folders new-files)))
    (current-directory ROOT-DIR)
    result))

(define (load-template filename)
  ; Reads from disk.
  (let* ([prefix (build-path ROOT-DIR TEMPLATES-DIR)]
         [to-path (λ (s) (build-path prefix (symbol->path s)))]
         [template (eval (read (open-input-string (file->string (to-path filename)))) ns)] ; xexp
         [children
          (list->set
           (map (λ (n)
                  (string->symbol (sxml:attr n 'target)))
                ((sxpath "//template") template)))])
    (cons template children)))

(define (load-templates template-names)
  ; Given a list of template names, load them recursively and produce a hash
  ; table associating template names to the unprocessed SXML content.
  ;
  ; This reads from disk.

  (let loop ([result (hash)]
              [todo (list->set template-names)])
    (if (set-empty? todo)
        result
        (let ([name (set-first todo)])
          (if (hash-has-key? result name)
              (loop result (set-remove todo name))
              (match (load-template name)
                [(cons template children)
                 (loop (hash-set result name template)
                       (set-union todo children))]))))))


; SXMLString SXMLString (List SXMLString) (Hash Symbol SXMLString) -> SXMLString
(define (apply-template template content styles templates)
  ; Given a template, the content, the styles, and a table of templates,
  ; recursively replace `<template>` and `<insert>` tags to apply the template.

  (define (get-template target)
    (hash-ref templates (string->symbol target)))

  (define (wrap-content elem content)
    ((sxml:modify
      (list
       "//insert"
       (λ (node _ctx _root)
         (let ([expr (sxml:attr node 'expr)])
           (sxml:change-attr
            node
            (list
             'expr
             (string-append
              "(let ((content " content ")) "
                  expr ")")))))))
     elem))

  (define (step-template xexp)
    ((sxml:modify
      (list
      "//template"
      (λ (node _ctx _root)
        (let* ([target (sxml:attr node 'target)]
               [content (sxml:content node)]
               ; cdr removes *TOP*
               [replacement (cdr (wrap-content
                                  (get-template target)
                                  (format "~v" content)))])
          replacement))))
     xexp))

  (define (step-insert xexp)
    ((sxml:modify
      (list
       "//insert"
       (λ (node _ctx _root)
         (let* ([expr (sxml:attr node 'expr)]
                [content-string (format "~v" content)]
                [styles-string (format "~v" styles)]
                [expr-wrapped
                 (string-append
                  "(let ((content " content-string ")"
                        "(styles " styles-string "))"
                        expr ")")]
                [value (eval (read (open-input-string expr-wrapped)) ns)])
           value))))
     xexp))

  (define (apply-once xexp)
    ; Do one step of resolving 'template tags and 'insert tags, in that order.
    ; Returns #f if no substitutions were made.
    (let* ([after-template-step (step-template xexp)]
           [after-insert-step (step-insert after-template-step)])
          ; When a template substition is made, how do we know where to put the
          ; children of the `<template>` tag in the new nodes? We wrap the
          ; Racket expressions inside `<insert>` tags with a `let` expression
          ; that binds `content` to the SXML of the content of the `<template>`
          ; tag. This way, every template gets to specify exactly where its
          ; content goes.
      (if (eq? xexp after-insert-step)
          #f
          after-insert-step)))

  (let loop ([template template])
    (match (apply-once template)
      [#f template]
      [template (loop template)])))

(define (write-file sxml dest)
  (let ([port (open-output-file dest)])
    (write-html sxml port)
    (close-output-port port)))

(define (main)
  (let* (; Load the config.
         [config (read-config)]

         ; Preprocess: convert ':kw to '#:kw
         [preprocessed (walk lisp-keyword->racket-keyword config)]

         ; Convert config to a hash table and check for duplicates
         [ht (config->hash-table preprocessed)]

         ; Check for cycles
         [_ (check-for-cycles (make-adjacency-list ht '#:styles ".css"))]
         [_ (check-for-cycles (make-adjacency-list ht '#:template ".sxml"))]

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
         
         ; Check that every file, folder, stylesheet, and template exists in the
         ; filesystem - except for disabled ones.
         [_ (check-exists ht)]

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
                      (build-path ROOT-DIR SRC-DIR
                      (symbol->path (hash-ref v '#:path)))))]
                   [styles (stylelist->xexp (hash-ref v '#:styles))])
             (values
              k
              (apply-template
                (hash-ref templates template)
                content
                styles
                templates)))))]
         [raw-plan (hash-filter plan (λ (v) (hash-ref v '#:raw)))])
    (begin
      (define dry-run #f)
      (hash-for-each
       files-sxml
       (λ (k v)
         (let* ([path (symbol->path k)]
                [dest (build-path ROOT-DIR DEST-DIR path)])
           (unless dry-run
            (make-parent-directory* dest)
            (write-file v dest))
           (printf "~a\n" dest)
           )))
      (hash-for-each
       raw-plan
       (λ (k v)
         (let* ([path (symbol->path k)]
                [src (build-path ROOT-DIR SRC-DIR path)]
                [dest (build-path ROOT-DIR DEST-DIR path)])
           (unless dry-run
            (make-parent-directory* dest)
            (copy-file src dest))
           (printf "~a\n" dest)
           )))
      )
    ))

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

;; testing
(define test-config
  '(:defaults (:template a.sxml
               :styles (a.css))
    :files ((:path u :template w :styles (w v))
            (:path v :template w :styles (x.css fake w))
            (:path w :template w.sxml :styles (y.css x.css))
            )
    :phony ((:path fake :styles z.css))
    ))

(define x (config->hash-table (walk lisp-keyword->racket-keyword (read-config))))

(define y (config->hash-table (walk lisp-keyword->racket-keyword test-config)))

(main)
