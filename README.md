# gschare.github.io
Website

[gschare.github.io](https://gschare.github.io/)

# How to build
0. Go to repo toplevel
1. `rm -r docs/` - clear the old website
2. `python3 scripts/index_posts.py` - generate the blog index
3. `python3 scripts/build.py` - build the site in `docs/`
4. `python3 -m http.server -d docs/` - view the result in browser at default
   port: `localhost:8000`; Ctrl-C to close the server

Then add, commit, and push.

# How to author blog posts
Create a new HTML file in the `blog/` folder. The file can (should) be a
fragment consisting of only the title tag and the marked-up post content,
the latter ideally wrapped in a `<main>` tag.
