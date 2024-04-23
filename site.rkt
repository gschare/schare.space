#lang racket

(require "src/build.rkt")

(define rules
  '(:defaults (:template article.sxml
               :styles (css/default.css))
    :files ((:path new.html
             :template new.sxml
             :styles (css/default.css css/new.css))
            (:path index.html)
            (:path now.html)
            (:path cv.html)
            (:path 404.html)
            (:path tidings/index.html)
            )
    :folders ((:path garden
               :template garden.sxml
               :styles (css/default.css css/garden.css))
              (:path tidings
               :template blog.sxml
               :styles (css/default.css css/tidings.css))
              )
    :phony ()
    :raw (:files (assets/cv.pdf
                  assets/hoogleplus-review.pdf
                  assets/semgus-review.pdf)
          :folders (writ css)
          )
    :disabled (:files ()
               :folders ()
               :folders ()
              )
    )
  )

(require racket/cmdline)

(define dry-run #f)
(define dest "docs")

(command-line
 #:program "site"
 #:once-each
 [("-d" "--dry-run") "Do not write any files" (set! dry-run #t)]
 [("-o" "--dest") dest "Destination folder" (void)]
 )

(build rules #:dest dest #:dry-run dry-run)

