#!/usr/bin/env python3

"""
merge_terraform_dirs.py

This script receives 2 path parameters pointing to terraform directories.
Optionally, an --out parameter let's the user specify an output directory.

The script then copies all the files from both directories into the given
output directory (the current one if not specified). If a file with the
same name exists in both directories then it appends the contents of the
second directory file to the first.

Usage:
  ./merge_terraform_dirs.py path_1 path_2 [--out out_path]
"""


import argparse
import os
import shutil
import tempfile


def copy_or_append_files(path: str, tmpdir) -> None:
    (dirpath, _, files) = next(os.walk(path))
    for file in files:
        src_file_path = os.path.join(dirpath, file)
        dest_file_path = os.path.join(tmpdir, file)
        if os.path.isfile(dest_file_path):
            # append to file because it already exists
            with open(dest_file_path, "a") as dest_file:
                with open(src_file_path, "r") as src_file:
                    dest_file.write("\n")
                    dest_file.write(src_file.read())
        else:
            shutil.copy(src_file_path, tmpdir)


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Merge two terraform configuration files directories "
            "into a single one"
        )
    )
    parser.add_argument("path_1", help="First terraform dir")
    parser.add_argument("path_2", help="Second terraform dir")
    parser.add_argument("-o", "--out", type=str, default=".",
        help="Output directory for the merged terraform configuration files"
    )
    args = parser.parse_args()

    path_1_exists = os.path.isdir(args.path_1)
    path_2_exists = os.path.isdir(args.path_2)
    path_out_exists = os.path.isdir(args.out)

    if not path_1_exists or not path_2_exists or not path_out_exists:
        parser.print_help()
        exit(1)

    with tempfile.TemporaryDirectory() as tmpdir:
        copy_or_append_files(args.path_1, tmpdir)
        copy_or_append_files(args.path_2, tmpdir)
        # move the merged files to the output directory
        (dirpath, _, files) = next(os.walk(tmpdir))
        for file in files:
            shutil.move(os.path.join(dirpath, file), args.out)

    print("Finished merging terraform files")


if __name__ == "__main__":
    main()
