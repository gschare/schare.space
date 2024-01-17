# Python 3.11.4

# meta
#   note: NO TITLE. title is in content.
#   template header into body
#   template content into body after header

# generate tidings post file

from os.path import join, isdir, isfile, relpath
from os import makedirs, walk
from shutil import copy
import json

TIDINGS_JSON = 'tidings.json'
SRC = 'src/'
TEMPLATES = 'templates/'
ASSETS = 'assets/'
TIDINGS = 'tidings/'
GARDEN = 'garden/'
STYLESHEET = join(ASSETS, 'style.css')
HEADER = join(TEMPLATES, 'header.html')
META = join(TEMPLATES, 'meta.html')

DOCS = 'docs/'

# Pages that just sit in the root directory.
# schema: (filename, tab)
LOOSE_LEAVES = [
        ('index.html', 'home'),
        ('cv.html', None),
        ('404.html', None),
        ('now.html', 'now'),
        ('new.html', None)
        ]

def build_page(content, tab=None):
    # tab: which thing in the nav bar to highlight, if any.

    with open(META, 'r') as f:
        meta = f.read()
        split = meta.find('\n</body>')
        before_body, after_body = meta[:split+1], meta[split:]

    with open(HEADER, 'r') as f:
        header = f.read()

    page = before_body + header + content + after_body

    # todo: replace this with a beautifulsoup query of the id
    if tab is not None:
        page += f'<script>document.getElementById("nav-{tab}").style.textDecoration = "underline";</script>'

    return page

def build_page_from_source(src, **kwargs):
    with open(src, 'r') as f:
        content = f.read()
        return build_page(content, **kwargs)

def write_page(content, dest):
    with open(dest, 'w') as f:
        f.write(content)

def check_for_sources():
    sources = {
            TIDINGS: isdir(join(SRC, TIDINGS)),
            GARDEN: isdir(join(SRC, GARDEN)),
            ASSETS: isdir(join(SRC, ASSETS)),
            STYLESHEET: isfile(join(SRC, STYLESHEET)),
            TEMPLATES: isdir(TEMPLATES),
            HEADER: isfile(HEADER),
            META: isfile(META),
            '.htaccess': isfile(join(SRC, '.htaccess'))
        }

    for leaf, _ in LOOSE_LEAVES:
        sources[leaf] = isfile(join(SRC, leaf))

    missing = list(filter(lambda x: not sources[x], sources.keys()))
    if len(missing) > 0:
        raise Exception('Missing source files/directories:\n\t' + '\n\t'.join(missing))

def write_nojekyll():
    with open('.nojekyll', 'w') as f:
        f.write('')

def copy_assets():
    makedirs(join(DOCS, ASSETS), exist_ok=True)
    with open(join(SRC, STYLESHEET), 'r') as s, open(join(DOCS, STYLESHEET), 'w') as d:
        d.write(s.read())

    artifacts = ['cv.pdf', 'semgus-review.pdf', 'hoogleplus-review.pdf']
    for a in artifacts:
        copy(join(SRC, ASSETS, a), join(DOCS, ASSETS, a))

def copy_folder(src, dst):
    makedirs(join(DOCS, dst), exist_ok=True)
    for path, dirs, files in walk(join(SRC, src)):
        for d in dirs:
            makedirs(join(DOCS, dst, relpath(path, start=join(SRC, src)), d), exist_ok=True)
        for file in files:
            if file[0] == '.':
                continue
            copy(join(path, file), join(DOCS, dst, relpath(path, start=join(SRC, src)), file))

def write_tidings():
    makedirs(join(DOCS, TIDINGS), exist_ok=True)

    with open(TIDINGS_JSON, 'r') as f:
        tidings_data = json.load(f)

    index = '<title>Tidings</title><main><div><h2>Posts</h2><ul style="list-style: none; padding-left: 0">'

    for root, _, posts in walk(join(SRC, TIDINGS)):
        for post in posts:
            if post[0] == '.':
                continue
            page = build_page_from_source(join(root, post), tab="tidings")
            write_page(page, join(DOCS, TIDINGS, post))

            title = tidings_data[post]['title']
            date = tidings_data[post]['date']
            preview = tidings_data[post]['preview']

            index_item = ('<li><a href="' + post + '"><p><b>' +
                          title + '</b></a><br>' + date + '<br><i>' + preview + '</i></p></li>')

            index += index_item

    index += '</ul></div></main>'
    write_page(build_page(index, tab="tidings"), join(DOCS, TIDINGS, 'index.html'))

def write_folder(folder, tab=None):
    makedirs(join(DOCS, folder), exist_ok=True)

    for path, dirs, files in walk(join(SRC, folder)):
        for d in dirs:
            makedirs(join(DOCS, folder, relpath(path, start=join(SRC, folder)), d), exist_ok=True)
        for file in files:
            if file[0] == '.':
                continue
            page = build_page_from_source(join(path, file), tab=tab)
            write_page(page, join(DOCS, folder, relpath(path, start=join(SRC, folder)), file))

def write_garden():
    write_folder(GARDEN, tab='garden')

def main():
    check_for_sources()

    # write `docs/`
    makedirs(DOCS, exist_ok=True)

    # write `docs/.nojekyll`
    write_nojekyll()

    # write `docs/.htaccess`
    with open(join(SRC, '.htaccess'), 'r') as src, open(join(DOCS, '.htaccess'), 'w') as dst:
        dst.write(src.read())

    # write `docs/assets/`
    copy_assets()

    # write misc pages
    for p, tab in LOOSE_LEAVES:
        write_page(build_page_from_source(join(SRC, p), tab=tab), join(DOCS, p))

    # write `docs/tidings/`
    write_tidings()

    # write `docs/garden/`
    write_garden()

    # write `docs/writ/`
    copy_folder('writ', 'writ')

if __name__ == '__main__':
    main()
