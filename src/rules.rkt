#lang racket

(provide walk
         rules->hash-table
         rules-closure)
(require hash-lambda) ; TODO: avoid using this library
(require racket/hash)
(require "io.rkt")
(require "hash.rkt")
(require "graph.rkt")

(define (walk f tree)
  (cond
   [(empty? tree) tree]
   [(list? (first tree)) (cons (walk f (first tree)) (walk f (rest tree)))]
   [else (cons (f (first tree)) (walk f (rest tree)))]))

(define (rules->hash-table rules)
  ; Parses and combines all the different rules into one big hash table with all
  ; the info, and checks for duplicates.
  ;
  ; You may regard this function as more or less a definition of the
  ; rules schema and the default behaviors.

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
             ; `(apply/hash f (apply hash x))` pattern for passing the rules
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

       (let ([ht
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
                     list-of-items)])
          ; Check for cycles
          (check-for-cycles (make-adjacency-list ht '#:styles ".css"))
          (check-for-cycles (make-adjacency-list ht '#:template ".sxml"))
          ht)))
     (apply hash rules)))

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
                               SRC-DIR
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
          (string-suffix? s ".sxml"))))

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
  
  ; First, check that every file, folder, stylesheet, and template exists in the
  ; filesystem - except for disabled ones.
  (check-exists rules-table)

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
