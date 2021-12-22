#!/usr/bin/env python3

from __future__ import annotations

from sys import argv, stdin
from re import compile as re_compile

PARSE_ERRORS = ["Bad token, not one of +, -, *, /"]
EVAL_ERRORS = [
    "Just a binop on the stack.",
    "Empty stack!",
    "Divide by zero!",
    "No program!"
]

ERRORS = [f"ERROR: {s}" for s in PARSE_ERRORS + EVAL_ERRORS]

RECOGNIZED_EXIT = 0
UNRECOGNIZED_EXIT = 1
ERR_EXIT = 2

# The second group represents scientific notation. It's a convenience for the
# TypeScript implementation, and should probably be removed if/when
# differential testing is a thing.
number_regex = re_compile(r"^-?([0-9]+\.[0-9][0-9]|[0-9]\.[0-9]+e(-|\+)[0-9]+)$")


def die(msg: str, code=ERR_EXIT):
    print("ERROR: " + msg)
    exit(code)


def recognize(s: str) -> bool:
    if s.endswith("\n"):
        s = s.strip("\n")
    if s == "" or s == "\n" or s in ERRORS:
        return True
    return number_regex.match(s) is not None


def main() -> int:
    if len(argv) != 1:
        die(f"Wrong number of arguments: {len(argv)}, expected 0 (use stdin)")
    for line in stdin:
        if not recognize(line):
            die(f"Unrecognized: {line}", code=UNRECOGNIZED_EXIT)


if __name__ == "__main__":
    exit(main())
