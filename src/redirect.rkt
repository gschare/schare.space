#lang racket

(provide redirect)
(require racket/system)
(require "io.rkt")
(require sxml)
(require html-parsing)

(define (redirect pathsym url #:title [title #f] #:base [base SRC-DIR] #:announce [announce #t])
  ; Given a path symbol (e.g. 'garden/myfile.html) specifying a desired output file
  ; and a URL to link to, generate standalone html redirecting to that URL and write
  ; that to file in the intermediate directory. This will overwrite the existing
  ; one.
  ;
  ; Optionally accepts a title to put on the page.
  ;
  ; Optionally accepts a base prefix to prepend to the path symbol to form the full path.
  ; Defaults to the SRC-DIR.
  ;
  ; Returns the symbol of the destination path.
  ;
  ; NOTE: be careful! You may have other rules that overwrite the same path.
  (if announce (displayln (format "Generate redirect page from ~a to ~a...." pathsym url)) (void))

  (let* ([path (symbol->path pathsym)]
         [src-path (build-path base path)]
         [rel-path (if (absolute-path? src-path)
                       (find-relative-path SRC-DIR src-path)
                       src-path)]
         [dest-path (build-path INTERMEDIATE-DIR rel-path)]
         [dest-sym (path->symbol rel-path)])
    (make-parent-directory* dest-path)
    (write-file (redirect-template url #:title title) dest-path)
    dest-sym))

(define (redirect-template url #:title [title #f])
  (if (not title)
      (set! title "Redirect")
      (void))
  (define desc (format "Redirecting to ~a" url))
  `(*TOP*
      ,(html->xexp "<!DOCTYPE html>")
      (html (@ (lang "en"))
        (head
          (meta (@ (name "viewport")
                   (content "width=device-width, initial-scale=1.0")))
          (meta (@ (charset "utf-8")))

          (meta (@ (name "twitter:card")
                   (content "summary_large_image")))
          (meta (@ (name "twitter:site")
                   (content "@ggschare")))
          (meta (@ (name "twitter:title")
                   (content ,title)))
          (meta (@ (name "twitter:description")
                   (content ,desc)))
          (meta (@ (name "twitter:image:src")
                   (content "https://schare.space/assets/img/nessie.jpg")))

          (meta (@ (property "og:title")
                   (content "schare.space: a website")))
          (meta (@ (property "og:type")
                   (content "website")))
          (meta (@ (property "og:description")
                   (content ,desc)))
          (meta (@ (property "og:image")
                   (content "https://schare.space/assets/img/nessie.jpg")))
          (meta (@ (property "og:site_name")
                   (content "schare.space")))

          (link (@ (rel "icon")
                   (href "/favicon.ico")
                   (type "image/x-icon")))

          (title ,title)

          (script (@ (data-goatcounter "https://schare.goatcounter.com/count")
                     (async)
                     (src "/js/count.js")))

          (meta (@ (http-equiv "refresh")
                   (content ,(format "0; URL=~a" url))))
      (body
        (a (@ (href ,url))
           ,url))))))
