import glob
import os
from operator import attrgetter


class dotdict(dict):
    __getattr__ = dict.get
    __setattr__ = dict.__setitem__
    __delattr__ = dict.__delitem__


def current_dir():
    return os.path.realpath(os.path.dirname(__file__))


def load_generators(parent_module, identifiers):
    generator_functions = {}
    for identifier in identifiers:
        generator_file = f"{parent_module}.{identifier}"
        generator_functions[identifier] = attrgetter(identifier)(
            __import__(generator_file)
        ).run

    def run(generator_name, data=dotdict()):
        return generator_functions[generator_name](data)

    return run


def list_files(path, extension=""):
    path = glob.iglob(os.path.join(path, f"**/*{extension}"), recursive=True)
    files = [p for p in path if os.path.isfile(p)]  # Discards directories
    files.sort(reverse=True)
    return files
