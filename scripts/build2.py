# Python 3.11.4

### Intro

#       __                   ___       __                           
#      /\ \              __ /\_ \     /\ \                          
#      \ \ \____  __  __/\_\\//\ \    \_\ \       _____   __  __    
#       \ \ '__`\/\ \/\ \/\ \ \ \ \   /'_` \     /\ '__`\/\ \/\ \   
#        \ \ \L\ \ \ \_\ \ \ \ \_\ \_/\ \L\ \  __\ \ \L\ \ \ \_\ \  
#         \ \_,__/\ \____/\ \_\/\____\ \___,_\/\_\\ \ ,__/\/`____ \ 
#          \/___/  \/___/  \/_/\/____/\/__,_ /\/_/ \ \ \/  `/___/> \
#                                                   \ \_\     /\___/
#                                                    \/_/     \/__/ 

# build.py
#
# Steps:
#   1. Read the config/config.json file.
#   2. Parse the config and check for files, possibly throwing errors.
#   3. Check for conflicts and determine the proper file build order.
#   4. Load each file one by one in the proper order, compile them, and write
#      them to the output folder.
#
# This means the file basically has 5 parts:
#   1. Parse the rules from s-exprs into a graph
#   2. Convert this graph into a stylesheet inheritance DAG by condensing strongly
#      connected components
#   3. Use the DAG to resolve the inheritance and get a list of all files to parse
#   4. Process each file in the list by parsing the HTML of the layout file,
#      assembling it, and writing it to disk

### Imports.

from os.path import join, isdir, isfile, relpath
from os import makedirs, walk
from shutil import copy
import json
from bs4 import BeautifulSoup

### Globals.

CONFIG_FILE = 'config/config.yml'
SRC_DIR = 'src/'
DEST_DIR = 'docs/'

### Config Format.
##
#
# We use a rule-based format for specifying the conf
#
# It is given as an s-expression, here denoted partly by example, partly by grammar.

'((defaults
   ((template default.html)
    (stylesheets default.css)))
  (files
   ((path <FILEPATH>)    ; relative to src/
    (template <TEMPLATE>?)
    (stylesheets <STYLE>*)))
  (folders
   ((path <FILEPATH>)    ; relative to src/
    (template <TEMPLATE>?)
    (stylesheets <STYLE>*)))
  )

# Currently, the path must end in a `/` if it is a folder. I may change this
# later, since it's kinda stupid. TODO: change this
#
# 
#
# <STYLE> may be provided as a path to a CSS stylesheet (determined by whether
# the token ends with `.css`), or as the name path of an existing file or folder in
# the repo which is registered elsewhere in the config. If so, this rule inherits all the paths from that rule. This
# allows for an arbitrary directed graph where the arrows mean "---- inherits
# from -->", which may be cyclic. Technically this is fine, because connected
# components in the graph share a (we detect such connected components to
# remove cycles), but there is no need to write them cyclically.
#
# For options which are not required, left off, or left blank, the corresponding
# default is used.
#
# For folders within folders, if `inherit` is `true`, then it will inherit the stylesheet settings of its parents
#
# The `recursive` option determines, for folders only, 
# If this is set, 
#
# if template or stylesheets is left off, or left blank, the default is used
#
# TODO: allow "markdown: true | false"
#
# TODO:

### Loading the config.
## Side effects: reading from disk.

def check_config_exists():
    if os.path.isfile(CONFIG_FILE):
        return True
    else:
        raise Exception(f'no config file found at `{CONFIG_FILE}`')

def read_config_file() -> str:
    with open(CONFIG_FILE, 'r') as f:
        return f.read()

def parse_config(config: str) -> dict:
    return json.loads(config)

def load_config() -> dict:
    check_config_exists()
    return parse_config(read_config_file())

### Validating the config.
## Effects: read

def check_duplicates(config: dict):
    paths = set()
    dests = set()

    raise Exception("duplicate source path found: ``")
    raise Exception("duplicate destination path found: ``")
    
    # TODO

def validate_config(config: dict):
    # TODO
    # check_duplicates(config_json)

### Determine build order.

def calculate_build_order(config: dict) -> list:
    # TODO
    return 

def 

### Building a file.

def assemble_file(src: str, layout: str, tab: str) -> str:
    # TODO

def resolve_layout()
    # TODO

### Processing a file.
## Side effects: reading and writing to disk.

def process_file(entry: dict):
    # TODO
    # read layout
    # read file

### Processing a folder.
def process_folder(entry: dict):
    # TODO

### Processing an entry.

def process_entry(entry: dict):
    # TODO

### Entry
def main():
    # TODO
    return

if __name__ == "__main__":
    main()
