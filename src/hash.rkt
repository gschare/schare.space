#lang racket

(provide hash-filter
         hash-filter-not
         by-flag
         hash-map-update)
(require racket/hash)

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
