# Python 3.11.4

# meta
#   note: NO TITLE. title is in content.
#   template header into body
#   template content into body after header

# generate blog post file

from os.path import join, isdir, isfile
from os import makedirs, walk

from blog_index import BLOG_INDEX

TEMPLATES_DIR = 'templates/'
ASSETS_DIR = 'assets/'
BLOG_DIR = 'blog/'
INDEX = 'index.html'
STYLESHEET = join(ASSETS_DIR, 'style.css')
HEADER = join(TEMPLATES_DIR, 'header.html')
META = join(TEMPLATES_DIR, 'meta.html')

OUT_DIR = 'docs/'

def build_page(content):
    with open(META, 'r') as f:
        meta = f.read()
        split = meta.find('\n</body>')
        before_body, after_body = meta[:split+1], meta[split:]

    with open(HEADER, 'r') as f:
        header = f.read()

    page = before_body + header + content + after_body

    return page

def build_page_from_source(src):
    with open(src, 'r') as f:
        content = f.read()
        return build_page(content)

def write_page(content, dest):
    with open(dest, 'w') as f:
        f.write(content)

def check_for_sources():
    sources = {
            BLOG_DIR: isdir(BLOG_DIR),
            ASSETS_DIR: isdir(ASSETS_DIR),
            TEMPLATES_DIR: isdir(TEMPLATES_DIR),
            INDEX: isfile(INDEX),
            STYLESHEET: isfile(STYLESHEET),
            HEADER: isfile(HEADER),
            META: isfile(META)
        }
    missing = list(filter(lambda x: not sources[x], sources.keys()))
    if len(missing) > 0:
        raise Exception('Missing source files/directories:\n\t' + '\n\t'.join(missing))

def write_nojekyll():
    with open('.nojekyll', 'w') as f:
        f.write('')

def copy_assets():
    makedirs(join(OUT_DIR, ASSETS_DIR), exist_ok=True)
    with open(STYLESHEET, 'r') as s, open(join(OUT_DIR, STYLESHEET), 'w') as d:
        d.write(s.read())
    with open('assets/cv.pdf', 'r') as s, open(join(OUT_DIR, 'assets', 'cv.pdf'), 'w') as d:
        d.write(s.read())

def write_index():
    index = build_page_from_source(INDEX)
    write_page(index, join(OUT_DIR, 'index.html'))

def write_blog():
    makedirs(join(OUT_DIR, BLOG_DIR), exist_ok=True)

    index = '<title>Blog</title><div><h3>Posts</h3><ul class="nobullet">'

    for root, _, posts in walk(BLOG_DIR):
        for post in posts:
            page = build_page_from_source(join(root, post))
            write_page(page, join(OUT_DIR, BLOG_DIR, post))

            title = BLOG_INDEX[post]['title']
            preview = BLOG_INDEX[post]['preview']

            index_item = ('<li><a href="' + post + '"><p><b>' +
                          title + '</b><br><i>' + preview + '</i></p></a></li>')

            index += index_item

    index += '</ul></div>'
    write_page(build_page(index), join(OUT_DIR, BLOG_DIR, 'index.html'))

def main():
    check_for_sources()

    # write `docs/`
    makedirs(OUT_DIR, exist_ok=True)

    # write `docs/.nojekyll`
    write_nojekyll()

    # write `docs/assets/`
    copy_assets()

    # write `docs/index.html`
    write_index()

    # write `docs/blog/`
    write_blog()

if __name__ == '__main__':
    main()
