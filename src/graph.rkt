#lang racket

(provide make-adjacency-list
         check-for-cycles
         resolve-graph)
(require "hash.rkt")

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
