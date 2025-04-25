#!/usr/bin/env bash
#
# Usage:
#   ./convert_excel_to_two_columns_delimited.sh /path/to/file.xlsx
#
# Description:
#   1. Extracts only column 1 of the spreadsheet into _input.csv.
#   2. Extracts only column 2 of the spreadsheet into _output.csv.
#   3. Appends `ǂ` after each row, ensuring multi-line fields remain intact.
# Function to perform CSV conversion using Python

# python_csv_convert() {
#     local base_dir="$1"
#     local base_name="$2"
#     local delimiter="$3"

#     python3 <<EOF
# import csv
# base_dir = "$base_dir"
# delimiter = "$delimiter"
# base_name = "$base_name"

# with open(f"{base_dir}/{base_name}_expected_input.csv") as infile, open(f"{base_dir}/{base_name}_input.csv", "w") as outfile:
#     for row in csv.reader(infile):
#         outfile.write((row[0] if row else "") + delimiter + "\n")

# with open(f"{base_dir}/{base_name}_expected_output.csv") as infile, open(f"{base_dir}/{base_name}_output.csv", "w") as outfile:
#     for row in csv.reader(infile):
#         outfile.write((row[0] if row else "") + delimiter + "\n")
# EOF
# }

# Updated convert_excel_to_csv function leveraging global paths and checking for column 2
convert_excel_to_csv() {
    local input_file="$1"
    local base_name
    base_name=$(basename "$input_file" .xlsx)
    mkdir -p "$CONVERTED_FILES_DIR" || return 1

    # remove old files
    rm -f "$CONVERTED_FILES_DIR/${base_name}_input.csv" \
          "$CONVERTED_FILES_DIR/${base_name}_output.csv"

    python3 <<EOF
import openpyxl, os, sys

wb = openpyxl.load_workbook("$input_file", data_only=True)
ws = wb.active

out_dir = "$CONVERTED_FILES_DIR"
delim = "ǂ"

# open output files
inp_path = os.path.join(out_dir, "${base_name}_input.csv")
out_path = os.path.join(out_dir, "${base_name}_output.csv")

with open(inp_path, "w", encoding="utf-8", newline="") as inf, \
     open(out_path, "w", encoding="utf-8", newline="") as outf:
    for row in ws.iter_rows(values_only=True):
        # column 1
        cell0 = row[0] if row and row[0] is not None else ""
        # column 2 (if exists)
        cell1 = row[1] if len(row) > 1 and row[1] is not None else ""
        # write, preserving any embedded newlines
        inf.write(str(cell0).replace("\\r\\n", "\\n") + delim + "\\n")
        outf.write(str(cell1).replace("\\r\\n", "\\n") + delim + "\\n")
EOF
}
