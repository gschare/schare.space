#lang racket

(require "src/build.rkt")
(require "src/tidings.rkt") ; blog builder

(define rules
  `(:defaults (:template article.sxml
               :styles (css/default.css))
    :files ((:path new.html
             :template new.sxml)
            (:path index.html
             :styles (css/default.css css/home.css))
            (:path now.html
             :styles (css/default.css css/now.css))
            (:path cv.html)
            (:path 404.html)
            ;(:path ,(index-tidings)
            ; :template blog.sxml
            ; :styles (css/default.css css/tidings.css))
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
                  assets/semgus-review.pdf
                  CNAME
                  ;,(rss-tidings)
                  )
          :folders (writ js css assets/img)
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

