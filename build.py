#!/usr/bin/env python3

import shutil
import os
import sys

# Path of build script
current_dir = os.path.realpath(os.path.dirname(__file__))

# Path of build output, clear and recreate
buildpath = os.path.join(current_dir, "build")
shutil.rmtree(buildpath, ignore_errors=True)
os.makedirs(buildpath, exist_ok=False)

# Add template generator directory as top level path (lets us directly import targets.py)
sitepath = os.path.join(current_dir, "site")
sys.path.insert(0, sitepath)
import targets

files = targets.template()

for file in files.keys():
    content = files[file]
    path = os.path.join(buildpath, file)
    print(f"Writing file {path}")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    buf = open(path, "wb")
    buf.write(content)
    buf.close()
