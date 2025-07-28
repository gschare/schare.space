#lang racket

; Given a pathsym to an XML file containing photographs by date, generate
; the folder structure (by date) and the file contents (as SXML) and write
; both to the intermediary directory.

(provide phlog)
(require "io.rkt")
(require xml)
(require sxml)
(require html-parsing)

(struct date (year month day))
(struct photo (link alt caption))
(struct day (date photos))

(define (show-date date)
  (string-join (list (date-year date)
                     (date-month date)
                     (date-day date))
               "-"))

(define month-table (hash "01" "January"
                          "02" "February"
                          "03" "March"
                          "04" "April"
                          "05" "May"
                          "06" "June"
                          "07" "July"
                          "08" "August"
                          "09" "September"
                          "10" "October"
                          "11" "November"
                          "12" "December"))

(define (anchor-or-invisible p x)
  (if p
    `(a (@ (href ,p))
        ,x)
    `(span ; (@ (class "invisible")) ; actually i'd rather it not be invisible...
           ,x)))

(define default-dark-mode '(script "document.body.classList.add('dark-mode'); document.getElementById('dark-mode-button').innerHTML = '☀️'; document.getElementById('dark-mode-button').title = 'Light mode';"))

(define (generate-sxml day prev-href next-href)
  (let* ([date (day-date day)]
         [title (string-append "Phlog | "
                               (hash-ref month-table (date-month date))
                               " "
                               (date-day date)
                               ", "
                               (date-year date))])
    `(*TOP*
      ,default-dark-mode
      (title ,title)
      (h1 ,title)
      ,(list 'p
           (anchor-or-invisible prev-href "Prev")
           " | "
           ;'(a (@ (href "../"))
           ;    "Month")
           '(a (@ (href "../../../all.html"))
               "All")
           " | "
           (anchor-or-invisible next-href "Next"))
      ,(cons 'div
        (cons '(@ (id "gallery")) ; Not an article .gallery!
        (map
         (λ (photo)
            `(figure (img (@ (src ,(photo-link photo))
                             (loading "lazy")
                             (alt ,(photo-alt photo))))
                     ,(if (photo-caption photo)
                      `(figcaption ,(html->xexp (photo-caption photo)))
                      '(div))))
         (day-photos day))))
      ,(list 'footer
           (anchor-or-invisible prev-href "Prev")
           " | "
           ;'(a (@ (href "../"))
           ;    "Month")
           '(a (@ (href "../../../all.html"))
               "All")
           " | "
           (anchor-or-invisible next-href "Next")))))

(define (parse-xml doc)
  (define trim (eliminate-whitespace '(alt caption a em strong p) not))

  (define (parse-date datestring)
    ; parses YYYY-MM-DD into a struct
    (date (substring datestring 0 4)
          (substring datestring 5 7)
          (substring datestring 8 10)))

  (define (get-el el-name parent)
    (let ([el (findf (λ (x) (equal? (element-name x) el-name)) (element-content parent))])
      (if el el (error "no such element"))))

  (define (get-attr attr-name el)
    (let ([attr (findf (λ (x) (equal? (attribute-name x) attr-name)) (element-attributes el))])
      (if attr (attribute-value attr) (error "no such attribute"))))

  (define (get-html el)
    ; when an element's content is html and we want that as a string
    (let ([s (open-output-string)])
      (for-each
       (λ (c) (write-xml/content c s))
       (element-content el))
      (get-output-string s)))

  (define (parse-photo photo-el)
    (let ([link (get-attr 'link photo-el)]
          [caption (get-el 'caption photo-el)]
          [alt (get-el 'alt photo-el)])
      ; TODO: id
      (photo link (get-html alt)
             (let ([cap (get-html caption)])
               (if (non-empty-string? cap)
                   cap
                   #f)))))

  (define (parse-day day-el)
    (let ([date (parse-date (get-attr 'date day-el))]
          [photos (map parse-photo (element-content (get-el 'photos day-el)))])
      (day date photos)))

  (let* ([root (document-element doc)]
         [root (trim root)]
         [days-list (element-content root)])
    (map parse-day days-list)))

(define (phlog pathsym)
  (displayln "Render phlog....")

  (let* ([src-path (build-path SRC-DIR (symbol->path pathsym))]
         [dest-folder (apply build-path (drop-right (explode-path (symbol->path pathsym)) 1))]
         [dest-path (build-path INTERMEDIATE-DIR dest-folder)]
         [dest-sym (path->symbol dest-folder)])

  ; Parse the XML file.
  (let* ([doc (call-with-input-file src-path (λ (in) (read-xml in)))]
         [days (sort (parse-xml doc) string<? #:key (λ (x) (show-date (day-date x))))]) ; : list day


  (cond [(null? days) dest-sym] ; stop here
        [else                   ; else, continue with >=1 days

  (define (build-web-path . components)
    (string-join (cons (symbol->string dest-sym) components)
                 "/"
                 #:before-first "/"
                 #:after-last "/"))

  ; Generate and write the files.
  (define (date-to-href date)
    (build-web-path (date-year date) (date-month date) (date-day date)))
  (define prev #f)
  (define next (let ([dates (map day-date days)])
                 (and (> (length dates) 1)
                      (drop dates 1)))) ; we use a zipper tactic
  (for-each
    (λ (day)
      (let* ([date (day-date day)]
             [dest (build-path dest-path (date-year date) (date-month date) (date-day date) "index.html")]
             [prev-href (and prev (date-to-href prev))]
             [next-href (and next (date-to-href (car next)))])
        (make-parent-directory* dest)
        (write-file (generate-sxml day prev-href next-href) dest)
        (set! next (and next (pair? (cdr next)) (cdr next)))
        (set! prev date)))
    days)
  
  ; Make index files.
  (define (make-year-index year months prev-year-href next-year-href)
    (let ([title (string-append "Phlog | " year)])
     `(*TOP*
       ,default-dark-mode
       (title ,title)
       (h1 ,title)
       ,(list 'p
            (anchor-or-invisible prev-year-href "Prev")
            " | "
            '(a (@ (href "../"))
                "Up")
            " | "
            (anchor-or-invisible next-year-href "Next"))
       ,(cons
         'ul
         (map (λ (m) `(li (a (@ (href ,(string-append m "/")))
                             ,(hash-ref month-table m))))
              months)))))

  (define (make-month-index year month days prev-month-href next-month-href)
    (let ([title (string-append "Phlog | " (hash-ref month-table month) " " year)])
     `(*TOP*
       ,default-dark-mode
       (title ,title)
       (h1 ,title)
       ,(list 'p
            (anchor-or-invisible prev-month-href "Prev")
            " | "
            '(a (@ (href "../"))
                "Year")
            " | "
            (anchor-or-invisible next-month-href "Next"))
       ,(cons
         'ul
         (map (λ (d) `(li (a (@ (href ,(string-append d "/")))
                             ,d)))
              days)))))

  (let ([groups (map
                 (λ (y)
                  (group-by ; by month within year buckets
                   (λ (d) (date-month d))
                   y))
                 (group-by ; by year
                  (λ (d) (date-year d)) ; by year
                  (reverse (map day-date days))))]) ; reverse so that we show later years, months, and days first.

    ; we start with the latest year and go back in time, so prev is the next in the list.
    (define prev-year (let ([years (map (λ (y) (date-year (first (first y)))) groups)])
                        (and (> (length years) 1)
                             (drop years 1)))) ; zipper tactic again
    (define next-year #f)
    (for-each
     (λ (y)
       (let* ([year (date-year (first (first y)))]
              [dest (build-path dest-path year "index.html")]
              [prev-year-href (and prev-year (build-web-path (car prev-year)))]
              [next-year-href (and next-year (build-web-path next-year))]
              [months (map (λ (m) (date-month (first m))) y)])
        (write-file (make-year-index year months prev-year-href next-year-href) dest)

        (define prev-month (and (> (length months) 1)
                                (drop months 1))) ; you'll never guess it... zipper tactic!
        (define next-month #f)
        (for-each
         (λ (m)
           (let* ([month (date-month (first m))]
                  [dest (build-path dest-path year month "index.html")]
                  [prev-month-href (and prev-month (build-web-path year (car prev-month)))]
                  [next-month-href (and next-month (build-web-path year next-month))]
                  [days (map date-day m)])
             (write-file (make-month-index year month days prev-month-href next-month-href) dest)
             (set! prev-month (and prev-month (pair? (cdr prev-month)) (cdr prev-month)))
             (set! next-month month)))
         y)

        (set! prev-year (and prev-year (pair? (cdr prev-year)) (cdr prev-year)))
        (set! next-year year)))
     groups))

  ; All time index, which lists every single post.
  (define (make-all-time)
    (let ([title (string-append "Phlog | All Posts")])
     `(*TOP*
       ,default-dark-mode
       (title ,title)
       (h1 ,title)
       ,(cons
         'ul
         (map (λ (day)
               (let* ([date (day-date day)]
                      [href (date-to-href date)])
                `(li (a (@ (href ,href))
                        ,(show-date date)))))
              days)))))

  (write-file (make-all-time) (build-path dest-path "all.html"))


  ; Overall index, which just links to the most recent post.
  (define (make-index link)
    `(*TOP*
      ,default-dark-mode
      (title "Phlog: taking the “social” out of “social media”")
      (h1 "Phlog")
      (p (@ (class "cursive"))
         "taking the " (span (@ (class "underline")) "social") " out of " (span (@ (class "underline")) "social media"))
      (p
       (a (@ (href ,link))
          "Go to latest post →"))
      (p
       (a (@ (href "all.html"))
          "See all →"))
      (a (@ (href "all.html"))
         (img (@ (src "/assets/img/garden/phlog/finally.jpg")
              (width "320px"))))))

  (write-file (make-index (date-to-href (day-date (last days)))) (build-path dest-path "index.html"))

  dest-sym]))))
