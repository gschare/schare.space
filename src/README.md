# Build System

## How this build script works
Steps:

   1. Read the config file which contains rules about how to assemble files.
   2. Parse the config and validate it, possibly throwing errors.
   3. Resolve the rules and determine a file build order.
   4. Load each file one by one, assemble them, and write them to the output
      folder.

This means the file basically has 5 parts:

   1. Parse the rules from s-exprs into a graph.
   2. Convert this graph into a stylesheet inheritance DAG by condensing
      strongly connected components.
   3. Use the DAG to resolve the inheritance and get a list of all files.
   4. Process each file in the list by parsing the HTML of the layout file,
      assembling it, and writing it to disk

## Config format
 We use a rule-based format for specifying the config. It is given as an
 s-expression (with keywords), here denoted partly by example, partly by
 grammar.

```racket
'(:defaults
  (:template <PATH>                ; relative to templates/
    :styles (<PATH> ...))           ; relative to css/
  :files
  ((:path <PATH>                   ; relative to src/
    :template <TEMPLATE>
    :styles (<STYLE> ...))
    ...)
  :folders
  ((:path <PATH>                   ; relative to src/
    :template <TEMPLATE>
    :styles (<STYLE> ...))
    ...)
  :phony
  ((:path <PATH>                   ; this can be anything
    :template <TEMPLATE>
    :styles (<STYLE> ...))
    ...)
  :raw
  (:files (<PATH> ...)
    :folders (<PATH> ...)
    )
  :disabled
  (:files (<PATH> ...)
    :folders (<PATH> ...)
    )
  )
```

The PATH of a folder or file rule is considered its name and unique identifier
as a rule. It is invalid to specify two or more rules with the same name; we
check for duplicates and reject rulesets containing duplicate rules.

For a given rule (call it `R`), <STYLE> may be provided as a path to a CSS
stylesheet (determined by whether the token ends with `.css`), or as the name
of another rule. If given as the name of another rule `S`, `R` inherits all
the styles from `S`.

This allows for an arbitrary directed graph where an edge (u,v) means
"u inherits from v". Cycles are possible, but invalid; we reject graphs with
cycles in them.

Technically it would be fine to have cycles, because nodes in the same
strongly connected component share the same set of styles. We could use
Kosaraju's algorithm to detect SCCs and convert the graph to a DAG, but then
it would be difficult to ensure stylesheets cascade properly. Instead,
we require the user to provide a DAG and then we assign a deterministic
stylesheet order on a per-rule basis by traversing the DAG.

Note that unexpected cascading can still happen when styles are listed in
certain orders. Consider rules u,v,w and stylesheets x,y, with edges
(u,v), (u,w), (v,w), (v,x), (w,x), (w,y). If v has [x,w] as its style list and
w has [y,x] as its list, then it will resolve to v=[x,y], w=[y,x], and
u=[x,y]. But if v has [w,x], then it will resolve to v=[y,x], w=[y,x] and
u=[y,x]. Be careful of this, and try to avoid redundancy. In most cases it
would be preferable to simply have v inherit w, unless we really want to swap
the order of x and y for v and u but not for w.

<TEMPLATE> can similarly point to either an actual template file (ending in
`.html`) or another rule. It is possible to form cycles here, too, but it is
invalid to do so (we check for cycles and reject graphs that contain them).

Templates must end in .sxml. Stylesheets must end in .css. HTML
fragments/source files have no requirements for extensions, but it helps to
end them with .html (to avoid conflicts or confusion). Folders should not end
in '/', and similarly must not conflict. This is subject to change.

For files, folders, and phonies, the following keywords are optional:

* `:template`
* `:styles`

If optional keywords are left off, or left blank, the corresponding
default is used.

When a folder rule is provided, its rules automatically apply to everything
inside it recursively. If a subfolder or file within the folder (at any depth)
has its own rule, it does not inherit (but you can explicitly ask it to
inherit by adding the name of its parent rule).

The :raw keyword specifies which files and folders should be copied to the
output directory without any processing. As usual, subfolders and files may
overwrite the recursive default, but duplicates of any PATHs are invalid

The :disabled keyword is similar, but instructs the build system to skip the
given files and folders. Unlike the other rules, :disabled is allowed
to overwrite other rules with the same name.

TODO: add a markdown flag
TODO: add a setting for custom build commands (like a makefile)
TODO: add nice syntax for arbitrary arguments passed to template

## Template format
This is actually very simple. A template (or layout) is a HTML
file containing some special tags that indicate how to assemble a final HTML
file using fragments of HTML from other files given as input or specified in
the template.

Currently, no advanced templating features are supported, but these can be
added later on as extensions to the templating language syntax.

The special tags are as follows:

* `<insert expr="EXPR">`
  * At assembly time, this is replaced by the DOM nodes that result from
    evaluating EXPR in the context of the available variable bindings. These
    nodes may be siblings; they are given as a list. No checking is performed;
    this may produce invalid HTML.
* `<template target="NAME">`
  * At assembly time, this is replaced by the template called NAME. Then,
    assembly instruction tags in that template are resolved until no more
    instruction tags can be found. Hence this is recursive. Cycles will result
    in infinite loops, so don't do that. Arguments are forwarded, not shadowed,
    so the user must provided all of the arguments for the entire tree of
    templates upfront.

Two arguments are passed by default: `content` and `styles`. The
`content` is the HTML fragment being processed, and the `styles` is a
list of `<link>` tags to the stylesheets specified in the rules for that file.
