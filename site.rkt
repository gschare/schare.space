#lang racket

(require "src/build.rkt")

(define rules
  '(:defaults (:template default.sxml
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

(build rules #:dest "docs" #:dry-run #f)
