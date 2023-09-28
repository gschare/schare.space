# Python 3.11.4

# meta
#   note: NO TITLE. title is in content.
#   template header into body
#   template content into body after header

# generate blog post file

from os.path import join, isdir, isfile
from os import makedirs, walk
from shutil import copy
import json

BLOG_INDEX = 'blog.json'
SRC_DIR = 'src/'
TEMPLATES_DIR = 'templates/'
ASSETS_DIR = 'assets/'
BLOG_DIR = 'blog/'
GARDEN_DIR = 'garden/'
INDEX = 'index.html'
STYLESHEET = join(ASSETS_DIR, 'style.css')
HEADER = join(TEMPLATES_DIR, 'header.html')
META = join(TEMPLATES_DIR, 'meta.html')

OUT_DIR = 'docs/'

# Pages that just sit in the root directory.
LOOSE_LEAVES = [
        'index.html',
        'cv.html',
        'not-found.html',
        'now.html'
        ]

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
            BLOG_DIR: isdir(join(SRC_DIR, BLOG_DIR)),
            GARDEN_DIR: isdir(join(SRC_DIR, GARDEN_DIR)),
            ASSETS_DIR: isdir(join(SRC_DIR, ASSETS_DIR)),
            STYLESHEET: isfile(join(SRC_DIR, STYLESHEET)),
            TEMPLATES_DIR: isdir(TEMPLATES_DIR),
            HEADER: isfile(HEADER),
            META: isfile(META),
            '.htaccess': isfile(join(SRC_DIR, '.htaccess'))
        }

    for leaf in LOOSE_LEAVES:
        sources[leaf] = isfile(join(SRC_DIR, leaf))

    missing = list(filter(lambda x: not sources[x], sources.keys()))
    if len(missing) > 0:
        raise Exception('Missing source files/directories:\n\t' + '\n\t'.join(missing))

def write_nojekyll():
    with open('.nojekyll', 'w') as f:
        f.write('')

def copy_assets():
    makedirs(join(OUT_DIR, ASSETS_DIR), exist_ok=True)
    with open(join(SRC_DIR, STYLESHEET), 'r') as s, open(join(OUT_DIR, STYLESHEET), 'w') as d:
        d.write(s.read())
    copy(join(SRC_DIR, ASSETS_DIR, 'cv.pdf'), join(OUT_DIR, ASSETS_DIR, 'cv.pdf'))

def write_blog():
    makedirs(join(OUT_DIR, BLOG_DIR), exist_ok=True)

    with open(BLOG_INDEX, 'r') as f:
        blog_data = json.load(f)

    index = '<title>Blog</title><div><h2>Posts</h2><ul class="nobullet">'

    for root, _, posts in walk(join(SRC_DIR, BLOG_DIR)):
        for post in posts:
            if post[0] == '.':
                continue
            page = build_page_from_source(join(root, post))
            write_page(page, join(OUT_DIR, BLOG_DIR, post))

            title = blog_data[post]['title']
            preview = blog_data[post]['preview']

            index_item = ('<li><a href="' + post + '"><p><b>' +
                          title + '</b><br><i>' + preview + '</i></p></a></li>')

            index += index_item

    index += '</ul></div>'
    write_page(build_page(index), join(OUT_DIR, BLOG_DIR, 'index.html'))

def write_garden():
    makedirs(join(OUT_DIR, GARDEN_DIR), exist_ok=True)

    for root, _, files in walk(join(SRC_DIR, GARDEN_DIR)):
        for file in files:
            if file[0] == '.':
                continue
            page = build_page_from_source(join(root, file))
            write_page(page, join(OUT_DIR, GARDEN_DIR, file))

def main():
    check_for_sources()

    # write `docs/`
    makedirs(OUT_DIR, exist_ok=True)

    # write `docs/.nojekyll`
    write_nojekyll()

    # write `docs/.htaccess`
    with open(join(SRC_DIR, '.htaccess'), 'r') as src, open(join(OUT_DIR, '.htaccess'), 'w') as dst:
        dst.write(src.read())

    # write `docs/assets/`
    copy_assets()

    # write misc pages
    for p in LOOSE_LEAVES:
        write_page(build_page_from_source(join(SRC_DIR, p)), join(OUT_DIR, p))

    # write `docs/blog/`
    write_blog()

    # write `docs/garden/`
    write_garden()

if __name__ == '__main__':
    main()
