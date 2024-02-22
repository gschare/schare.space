# Python 3.11.4

# index_posts.py

# 
#                 __                                              __             
#  __            /\ \                                            /\ \__          
# /\_\    ___    \_\ \     __   __  _      _____     ___     ____\ \ ,_\   ____  
# \/\ \ /' _ `\  /'_` \  /'__`\/\ \/'\    /\ '__`\  / __`\  /',__\\ \ \/  /',__\ 
#  \ \ \/\ \/\ \/\ \L\ \/\  __/\/>  </    \ \ \L\ \/\ \L\ \/\__, `\\ \ \_/\__, `\
#   \ \_\ \_\ \_\ \___,_\ \____\/\_/\_\    \ \ ,__/\ \____/\/\____/ \ \__\/\____/
#    \/_/\/_/\/_/\/__,_ /\/____/\//\/_/     \ \ \/  \/___/  \/___/   \/__/\/___/ 
#                                            \ \_\                               
#                                             \/_/                               

from bs4 import BeautifulSoup
from os.path import join, isdir
from os import walk

PREVIEW_LENGTH = 140
SRC_DIR = 'src/tidings/'
DEST_FILE = 'index.html'

def check_tidings_exists():
    # Effects: read
    if not isdir(SRC_DIR):
        raise Exception('no `src/tidings/` folder found in current directory')
    else:
        return True

def gather_posts_data() -> dict:
    # Effects: read
    index = {}

    for root, _, posts in walk(SRC_DIR):
        for post in posts:
            with open(join(root, post), 'r') as f:
                soup = BeautifulSoup(f, 'html.parser')
            title = str(soup.title.string)
            date = str(soup.find(id='date').string)
            content = soup.main
            if not content:
                content = BeautifulSoup('', 'html.parser')
            for header in content.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
                if header:
                    header.decompose()
            content.find(id='date').decompose()
            plain_text = ' '.join(content.stripped_strings)
            preview = plain_text[:PREVIEW_LENGTH] + '...'
            index[post] = {'title': title, 'date': date, 'preview': preview}
    
    return index

def construct_list(index: dict) -> str:
    order = sorted(index, key=lambda i: index[i]['date'])

    the_list = ""

    for post in order:
        title = index[post]['title']
        date = index[post]['date']
        preview = index[post]['preview']

        list_item = ('<li><a href="' + post + '"><p><b>' +
                      title + '</b></a><br>' +
                      date + '<br><i>' +
                      preview + '</i></p></li>')

        the_list += list_item

    return the_list

def write_index_file(index: dict):
    # Effects: write
    page = '<title>Tidings</title><main><div><h1>Posts</h1><ul style="list-style: none; padding-left: 0">'
    page += construct_list(index)
    page += '</ul></div></main>'

    with open(join(SRC_DIR, DEST_FILE), 'w') as f:
        f.write(page)

def main():
    # Effects: read, write
    check_tidings_exists()
    index = gather_posts_data()
    write_index_file(index)

if __name__ == '__main__':
    main()
