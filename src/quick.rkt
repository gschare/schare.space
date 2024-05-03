#lang racket

; Script for doing a "quick" build of just one file, using a generic template.
; This creates a standalone file (CSS in a `<style>` tag) and writes it to /tmp/.

; TODO: find a way to include `>` in style tag.

(require "templates.rkt")
(require "io.rkt")
(require html-parsing)
(require racket/cmdline)
(require sxml)

; TODO: work out correct path to templates and styles
(define-values (in out)
  (command-line
   #:program "quick"
   #:args (in out)
   (values in out)))

(define style "css/default.css")
(define template 'article.sxml)
(define templates-ht (load-templates (list template)))
(define style-list
  (list
    (sxml:change-content
     '(style)
      `(,(file->string
          (build-path SRC-DIR (string->path style)))))))
(define content (html->xexp (file->string in)))

(define xexp-string (apply-template (hash-ref templates-ht template)
                                    content
                                    style-list
                                    templates-ht))
(make-parent-directory* out)
(write-file xexp-string out)
