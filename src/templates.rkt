#lang racket

(provide stylelist->xexp
         load-templates
         apply-template)

(require html-parsing)
(require html-writing)
(require sxml)
(require "io.rkt")

(define-namespace-anchor nsa)
(define ns (namespace-anchor->namespace nsa))

(define (stylelist->xexp stylelist)
  (map
   (λ (s)
     (let ([href (string-append "/" (symbol->string s))])
       `(link (@ (rel "stylesheet")
                 (type "text/css")
                 (href ,href)))))
   stylelist))

(define (load-template filename)
  ; Reads from disk.
  (let* ([prefix TEMPLATES-DIR]
         [to-path (λ (s) (build-path prefix (symbol->path s)))]
         [template (eval (read (open-input-string (file->string (to-path filename)))) ns)] ; xexp
         [children
          (list->set
           (map (λ (n)
                  (string->symbol (sxml:attr n 'target)))
                ((sxpath "//template") template)))])
    (cons template children)))

(define (load-templates template-names)
  ; Given a list of template names, load them recursively and produce a hash
  ; table associating template names to the unprocessed SXML content.
  ;
  ; This reads from disk.

  (let loop ([result (hash)]
              [todo (list->set template-names)])
    (if (set-empty? todo)
        result
        (let ([name (set-first todo)])
          (if (hash-has-key? result name)
              (loop result (set-remove todo name))
              (match (load-template name)
                [(cons template children)
                 (loop (hash-set result name template)
                       (set-union todo children))]))))))


; SXMLString SXMLString (List SXMLString) (Hash Symbol SXMLString) -> SXMLString
(define (apply-template template content styles templates)
  ; Given a template, the content, the styles, and a table of templates,
  ; recursively replace `<template>` and `<insert>` tags to apply the template.

  (define title
    (let ([titles ((sxpath "//title") content)])
     (if (empty? titles)
         (let ([h1s ((sxpath "//h1") content)])
             (if (empty? h1s) "schare.space"
                 (string-normalize-spaces (sxml:text (first h1s)))))
         (string-normalize-spaces (sxml:text (first titles))))))

  (define (replace-og-title xexp)
    ((sxml:modify
      (list
       "//meta[@property='og:title']"
       (λ (node _ctx _root)
         (sxml:change-attr
          node
          (list 'content title))))
      (list
       "//meta[@name='twitter:title']"
       (λ (node _ctx _root)
         (sxml:change-attr
          node
          (list 'content title)))))
      xexp))

  (define (get-template target)
    (hash-ref templates (string->symbol target)))

  (define (wrap-content elem content)
    ((sxml:modify
      (list
       "//insert"
       (λ (node _ctx _root)
         (let ([expr (sxml:attr node 'expr)])
           (sxml:change-attr
            node
            (list
             'expr
             (string-append
              "(let ((content " content ")) "
                  expr ")")))))))
     elem))

  (define (step-template xexp)
    ((sxml:modify
      (list
      "//template"
      (λ (node _ctx _root)
        (let* ([target (sxml:attr node 'target)]
               [content (sxml:content node)]
               ; cdr removes *TOP*
               [replacement (cdr (wrap-content
                                  (get-template target)
                                  (format "~v" content)))])
          replacement))))
     xexp))

  (define (step-insert xexp)
    ((sxml:modify
      (list
       "//insert"
       (λ (node _ctx _root)
         (let* ([expr (sxml:attr node 'expr)]
                [content-string (format "~v" content)]
                [styles-string (format "~v" styles)]
                [expr-wrapped
                 (string-append
                  "(let ((content " content-string ")"
                        "(title \"" title "\")"
                        "(styles " styles-string "))"
                        expr ")")]
                [value (eval (read (open-input-string expr-wrapped)) ns)])
           value))))
     xexp))

  (define (apply-once xexp)
    ; Do one step of resolving 'template tags and 'insert tags, in that order.
    ; Returns #f if no substitutions were made.
    (let* ([after-template-step (step-template xexp)]
           [after-insert-step (step-insert after-template-step)])
          ; When a template substition is made, how do we know where to put the
          ; children of the `<template>` tag in the new nodes? We wrap the
          ; Racket expressions inside `<insert>` tags with a `let` expression
          ; that binds `content` to the SXML of the content of the `<template>`
          ; tag. This way, every template gets to specify exactly where its
          ; content goes.
      after-insert-step))

  (let loop ([template template])
    (if (and (empty? ((sxpath "//template") template))
             (empty? ((sxpath "//insert") template)))
        (replace-og-title template)
        (loop (apply-once template)))))
