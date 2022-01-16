import os
from pathlib import Path

MODULE_ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT_DIR = Path(os.path.join(MODULE_ROOT_DIR, "..", "..")).resolve()
TESTDATA_ROOT_DIR = os.path.join(PROJECT_ROOT_DIR, "testdata")
