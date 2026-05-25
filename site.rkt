#lang racket

(require "src/build.rkt")
(require "src/custom.rkt")

; Custom builders
;(require "src/tidings.rkt") ; blog builder
(require "src/md.rkt")
(require "src/xml.rkt")
(require "src/phlog.rkt")
(require "src/redirect.rkt")
(require "src/io.rkt")

(require racket/cmdline)

(define dry-run #f)
(define silent #f)
(define verbose #f)
(define dest "docs")

(command-line
 #:program "site"
 #:once-each
 [("-d" "--dry-run") "Do not write any files" (set! dry-run #t)]
 [("-o" "--dest") dest "Destination folder" (void)]
 [("-s" "--silent") "Silence output" (set! silent #t)]
 [("-v" "--verbose") "Verbose output" (set! verbose #t)]
 )

(define (displayln-unless-silent . args) (unless silent (apply displayln args)))
(define (display-unless-silent . args) (unless silent (apply display args)))

(begin
  (display-unless-silent "Empty temp....")
  (void (time-build-step (system "rm -r temp/")))
  (void (time-build-step (system "mkdir temp")))
  (displayln-unless-silent (format-runtime-seconds (total-runtime-seconds))))

(displayln-unless-silent "Defining rules....")
(define rules (time-build-step
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
             :template garden-no-dark.sxml
             :styles (css/default.css css/article.css css/garden.css
                      css/background.css))
            (:path garden/links.html
             :preprocessed #t
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            (:path ,(custom xml 'garden/books/index.xml)
             :preprocessed (garden/books/index.xslt garden/books/index.xml)
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            (:path garden/books/index.html
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            (:path ,(custom xml 'garden/flog/index.xml)
             :preprocessed garden/flog/index.xml
             :template garden.sxml
             :styles (css/default.css css/article.css css/garden.css css/wide.css))
            ;(:path ,(index-tidings)
            ; :template blog.sxml
            ; :styles (css/default.css css/tidings.css))
            (:path ,(custom md 'lab/index.md)
             :template garden.sxml
             :preprocessed lab/index.md
             :styles (css/default.css css/article.css css/garden.css))
            (:path lab/box.html
             :template default.sxml
             :styles (css/default.css))
            (:path lab/changes/hexagram/index.html
             :template default.sxml
             :styles (css/default.css css/article.css))
            (:path ,(custom md 'lab/changes/about.md)
             :preprocessed lab/changes/about.md ; tells the build system to check the cache for this file instead of the preprocessed HTML file
             :template article.sxml
             :styles (css/default.css css/article.css))
            (:path ,(custom redirect 'garden/shanawdithit.html "https://docs.google.com/presentation/d/1RjYAYZnmckHroYHq-ftTMQjY7AvsoXlN1EJ8WpX-SJU/edit?usp=sharing" #:title "Shanawdithit's maps and more")
             :preprocessed #t
             :template redirect.sxml)
            (:path ,(custom md 'vis-a2/index.md)
             :preprocessed vis-a2/index.md
             :template article-headerless.sxml
             :styles (css/default.css css/article.css css/wide.css))
            (:path ,(custom md 'vis-a3/index.md)
             :preprocessed vis-a3/index.md
             :template article-headerless.sxml
             :styles (css/default.css css/article.css css/wide.css))
            (:path ,(custom md 'vis-a4/index.md)
             :preprocessed vis-a4/index.md
             :template article-headerless.sxml
             :styles (css/default.css css/article.css css/wide.css))
            (:path lab/mothership/index.html
             :template boilerplate.sxml
             :styles (lab/mothership/character.css))
            )
    :folders (
              (:path ,(custom phlog 'garden/phlog/index.xml)
               :preprocessed 'garden/phlog/index.xml
               :template garden.sxml
               :styles (css/default.css css/garden.css css/phlog.css))
              (:path ,(custom md* 'garden #:recursive #t)
               :preprocessed #t ; unfortunately no good way to do this yet until I can defer the computation and tell it to locate the source when the rules process this folder rule.
               :template garden.sxml
               :styles (css/default.css css/article.css css/garden.css))
              (:path ,(custom md* 'notes)
               :preprocessed #t
               :template garden.sxml
               :styles (css/default.css css/article.css))
              (:path ,(custom md* 'question #:recursive #t)
               :preprocessed #t
               :template garden.sxml
               :styles (css/default.css css/article.css))
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
              (:path lab/changes
               :template default.sxml
               :styles (css/default.css css/wide.css css/article.css))
              (:path lab/changes/hexagram
               :template hexagram.sxml
               :styles (css/default.css css/article.css css/hexagram.css))
              (:path garden/aphorisms
               :template garden.sxml
               :styles (css/default.css css/garden.css css/wide.css))
              ;(:path ,(string->symbol "-")
              ; :template garden.sxml
              ; :styles (css/default.css css/article.css))
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
                  lab/changes/app.js
                  lab/changes/hexagram.js
                  ;lab/dnd/mothership/app.js
                  ;lab/dnd/mothership/character.css
                  .nojekyll
                  )
          :folders (writ js css assets/img assets/fonts assets/papers lab
                    assets/docs
                    assets/question
                    garden/jot/src
                    garden/tamas
                    garden/manifold-revealing
                    vis-a2/img
                    vis-a3/img
                    vis-a4/img
                    .well-known
                    )
          )
    :disabled (:files ()
               :folders ()
              )
    )
  ))
(displayln-unless-silent (format "Rules defined in ~a seconds." (format-runtime-seconds)))

;TODO: compile all markdown sources into html sources using pandoc before building?
(build rules #:dest dest #:dry-run dry-run #:silent silent #:verbose verbose)

