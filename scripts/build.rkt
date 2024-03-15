#lang racket

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         ;
;     __                   ___       __              __      __           ;
;    /\ \              __ /\_ \     /\ \            /\ \    /\ \__        ;
;    \ \ \____  __  __/\_\\//\ \    \_\ \       _ __\ \ \/'\\ \ ,_\       ;
;     \ \ '__`\/\ \/\ \/\ \ \ \ \   /'_` \     /\`'__\ \ , < \ \ \/       ;
;      \ \ \L\ \ \ \_\ \ \ \ \_\ \_/\ \L\ \  __\ \ \/ \ \ \\`\\ \ \_      ;
;       \ \_,__/\ \____/\ \_\/\____\ \___,_\/\_\\ \_\  \ \_\ \_\ \__\     ;
;        \/___/  \/___/  \/_/\/____/\/__,_ /\/_/ \/_/   \/_/\/_/\/__/     ;
;                                                                         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Welcome to build.rkt.
; Author: Gregory Schare, March 2024.
;
;; How this build script works
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Steps:
;   1. Read the config file which contains rules about how to assemble files.
;   2. Parse the config and validate it, possibly throwing errors.
;   3. Resolve the rules and determine a file build order.
;   4. Load each file one by one, assemble them, and write them to the output
;      folder.
;
; This means the file basically has 5 parts:
;   1. Parse the rules from s-exprs into a graph.
;   2. Convert this graph into a stylesheet inheritance DAG by condensing
;      strongly connected components.
;   3. Use the DAG to resolve the inheritance and get a list of all files.
;   4. Process each file in the list by parsing the HTML of the layout file,
;      assembling it, and writing it to disk
;
;; Config format
;;;;;;;;;;;;;;;;
;
; We use a rule-based format for specifying the config. It is given as an
; s-expression (with keywords), here denoted partly by example, partly by
; grammar.
;
;     '(:defaults
;        (:template <PATH>                ; relative to templates/
;         :stylesheets (<PATH> ...))      ; relative to styles/
;       :files
;        ((:path <PATH>                   ; relative to src/
;          :template <TEMPLATE>
;          :stylesheets (<STYLE> ...))
;         ...)
;       :folders
;        ((:path <PATH>                   ; relative to src/
;          :template <TEMPLATE>
;          :stylesheets (<STYLE> ...))
;         ...)
;       :phony
;        ((:name <NAME>
;          :template <TEMPLATE>
;          :stylesheets (<STYLE> ...))
;         ...)
;       )
;
; The PATH of a folder or file rule is considered its name and unique identifier
; as a rule. It is invalid to specify two or more rules with the same name; we
; check for duplicates and reject rulesets containing duplicate rules.
;
; For a given rule (call it `R`), <STYLE> may be provided as a path to a CSS
; stylesheet (determined by whether the token ends with `.css`), or as the name
; of another rule. If given as the name of another rule `S`, `R` inherits all
; the styles from `S`.
;
; This allows for an arbitrary directed graph where the arrows mean
; "---- inherits from -->", which may be cyclic. Technically this is fine,
; because nodes in the same strongly connected component share the same set of
; styles (we detect such connected components to remove cycles and form a DAG),
; but there is no need to write them cyclically. But go ahead and do that if you
; want to I guess?
;
; <TEMPLATE> can similarly point to either an actual template file (ending in
; `.html`) or another rule. It is possible to form cycles here, too, but it is
; invalid to do so (we check for cycles and reject graphs that contain them).
;
; For files, folders, and phonies, `:template` and `:stylesheets` are optional.
;
; If optional keywords are left off, or left blank, the corresponding
; default is used.
;
; When a folder rule is provided, its rules automatically apply to everything
; inside it recursively. If a subfolder or file within the folder (at any depth)
; has its own rule, it does not inherit (but you can explicitly ask it to
; inherit by adding the name of its parent rule).
;
; TODO: add a markdown flag
; TODO: add nice syntax for arbitrary arguments passed to template
;
;
;; Template format
;;;;;;;;;;;;;;;;;;
;
; This is actually very simple. A template (or layout) is a HTML
; file containing some special tags that indicate how to assemble a final HTML
; file using fragments of HTML from other files given as input or specified in
; the template.
;
; Currently, no advanced templating features are supported, but these can be
; added later on as extensions to the templating language syntax.
;
; The special tags are as follows:
;
;   <insert src="VAR">
;   At assembly time, this is replaced by the DOM nodes given by the argument
;   with name VAR. These nodes may be siblings; they are given as a list.
;   
;   <template src="PATH">
;   At assembly time, this is replaced by the template at PATH. Then, assembly
;   instruction tags in that template are resolved until no more instruction
;   tags can be found. Hence this is recursive. Cycles will result in infinite
;   loops, so don't do that. Arguments are forwarded, not shadowed, so the user
;   must provided all of the arguments for the entire tree of templates upfront.
;
; A template takes some number of keyword arguments (which are all symbols) that
; fill in its assembly-time variables.
;
; Two arguments are passed by default: `:content` and `:stylesheets`. The
; `:content` is the HTML fragment being processed, and the `:stylesheets` is a
; list of `<link>` tags to the stylesheets specified in the rules for that file.
; 

(define (hello world)
  "hello")

(hello "world")

; ; emacs lisp:
;(with-temp-buffer
; (insert-file-contents "~/dev/github/gschare.github.io/src/index.html")
; (libxml-parse-html-region (point-min) (point-max)))

; ; ^^ define the above as x...
; (dom-by-id (dom-append-child (dom-by-tag x 'main) (dom-node 'test '((id . "new")))) "new")


(define x
'(#:defaults (:template default.html
             :stylesheets default.css)
  #:files ((:path new.html
           :template new.html)
          (:path index.html)))
)

(define (f #:defaults defaults #:files files)
  (list defaults files))

(apply f x)

(require hash-lambda)

(apply/hash f (hash '#:defaults '() '#:files '()))

(keyword-apply f '(#:defaults () #:files ()))

(define (g x #:y y)
  (* x y))
 l
(g 5)
