import os
import sys
from pathlib import Path

dirname = sys.argv[1]

def recurse_subdir(path: Path) -> None:
    for sub in path.iterdir():
        if sub.is_dir():
            return recurse_subdir(sub)

        os.system(f"nimpretty ./{sub}")

recurse_subdir(Path(dirname))