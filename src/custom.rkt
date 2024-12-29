#lang racket

(provide custom
         ;custom*
         )
(require "io.rkt")
(require hash-lambda)

; Allows you to provide a custom procedure for preprocessing files
; before they are assembled by the build script.
;
; Examples: rendering Markdown, using XSLT to render XML, or other niche
; procedures which are not otherwise easy to do in this system.
;
; Few guarantees are provided.
;
; The only contract to follow: the procedure you provide must take as
; input a pathsymbol indicating which file or folder it operates on
; and return the path the site configuration should use.
;
; We *suggest* using sxml procedures and only reading and writing that
; file or folder, but you are not limited to this.

(define custom
  (hash-lambda
   args
   (let ([proc (args-hash-first args)]
         [pathsym (args-hash-first (args-hash-rest args))]
         [args (args-hash-rest (args-hash-rest args))])
     (apply/hash proc (args-hash-cons pathsym args)))))
