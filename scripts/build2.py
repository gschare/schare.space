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
