from pathlib import Path

MODULE_ROOT_DIR = Path(Path(__file__).resolve()).parent
PROJECT_ROOT_DIR = Path(MODULE_ROOT_DIR).parent.parent
TESTDATA_ROOT_DIR = Path(PROJECT_ROOT_DIR) / "testdata"
