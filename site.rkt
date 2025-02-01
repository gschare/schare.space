#lang racket

(require "src/build.rkt")
(require "src/custom.rkt")

; Custom builders
;(require "src/tidings.rkt") ; blog builder
(require "src/md.rkt")
(require "src/xml.rkt")
(require "src/phlog.rkt")

(system "rm -r temp/")
(system "mkdir temp")

(define rules
  `(:defaults (:template article.sxml
               :styles (css/default.css css/article.css))
    :files ((:path new.html
             :template new.sxml
             :styles (css/default.css css/new.css))
            (:path index.html
             :styles (css/default.css css/article.css css/home.css))
            (:path now.html
             :template article.sxml
             :styles (css/default.css css/article.css css/now.css))
            (:path cv.html)
            (:path 404.html)
            (:path tidings/index.html
             :template blog.sxml
             :styles (css/default.css css/article.css css/tidings.css))
            (:path assets/docs/cartwheel.html
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/background.css))
            (:path garden/microblog.html
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css
                      css/background.css))
            (:path garden/aphorisms/index.html
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            (:path garden/links.html
             :preprocessed #t
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            (:path garden/worm.html
             :template article-headerless.sxml
             :styles (css/default.css css/article.css css/garden.css))
            (:path ,(custom xml 'garden/books/index.xml)
             :preprocessed #t
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            (:path ,(custom xml 'garden/flog/index.xml)
             :preprocessed #t
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            ;(:path ,(index-tidings)
            ; :template blog.sxml
            ; :styles (css/default.css css/tidings.css))
            (:path lab/box.html
             :template default.sxml
             :styles (css/default.css))
            )
    :folders (
              (:path ,(custom phlog 'garden/phlog/index.xml)
               :preprocessed #t
               :template garden.sxml
               :styles (css/default.css css/garden.css css/phlog.css))
              (:path ,(custom md* 'garden #:recursive #t)
               :preprocessed #t
               :template garden.sxml
               :styles (css/default.css css/article.css css/garden.css))
              (:path ,(custom md* 'tidings #:recursive #t)
               :preprocessed #t
               :template blog.sxml
               :styles (css/default.css css/tidings.css css/article.css css/background.css))
              ;(:path tidings
              ; :template blog.sxml
              ; :styles (css/default.css css/tidings.css css/article.css css/background.css))
              (:path garden/sea
               :template garden.sxml
               :styles (css/default.css css/article.css css/garden.css css/sea.css))
              ;(:path garden/jot
              ; :template default.sxml
              ; :styles (css/default.css css/garden.css))
              )
    :phony ()
    :raw (:files (assets/cv.pdf
                  assets/hoogleplus-review.pdf
                  assets/semgus-review.pdf
                  favicon.ico
                  CNAME
                  ;,(rss-tidings)
                  garden/process-tree/script.js
                  garden/process-tree/style.css
                  )
          :folders (writ js css assets/img assets/fonts assets/papers lab
                    garden/jot/src
                    garden/tamas
                    )
          )
    :disabled (:files ()
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

;TODO: compile all markdown sources into html sources using pandoc before building?
(build rules #:dest dest #:dry-run dry-run)

