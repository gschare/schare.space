# gschare.github.io
Website

[gschare.github.io](https://gschare.github.io/)

## How to build
0. Go to repo toplevel
1. `rm -r docs/` - clear the old website
2. `python3 src/index_posts.py` - generate/update the blog index in
   `content/tidings/`
3. `racket site.rkt` - generate/update the site in `docs/`
4. `python3 -m http.server -d docs/` - view the result in browser at default
   port: `localhost:8000`; Ctrl-C to close the server

Then add, commit, and push.

## How to add new pages
1. Create a new HTML file somewhere in the `content/` directory.
2. Add a rule to the [config](site.rkt) for the new page. Note that many folders register their contents
   recursively, so your new page may already have an implicit entry. Check the
   config.
3. Rebuild the entire site as usual to view your new post on the webserver.

You can also create new templates and assets (e.g. CSS files) to help define
the look of your new page.

See [here](templates/README.md) for information on authoring templates.

## How to author blog posts
1. Create a new HTML file in the `tidings/` folder. The file should be an HTML
   fragment containing a `<title>` tag and an element containing the date with `id="date"`.
2. Run `python3 src/index_posts.py` from the repo toplevel. This updates
   the blog index with your new post.
3. Rebuild the entire site as usual to view your new post on the webserver.
