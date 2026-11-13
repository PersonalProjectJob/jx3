"""Compatibility entry point; the canonical engine lives inside xMacro."""
from pathlib import Path
import sys

_ENGINE_DIR = Path(__file__).resolve().parent.parent / "interface" / "xMacro"
sys.path.insert(0, str(_ENGINE_DIR))
from HoldKeyEngine import *

if __name__ == "__main__":
    raise SystemExit(main())
