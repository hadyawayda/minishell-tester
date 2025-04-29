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
    local base=$(basename "$input_file" .xlsx)

    mkdir -p "$CONVERTED_FILES_DIR" || {
        echo "Error: cannot create $CONVERTED_FILES_DIR" >&2
        return 1
    }
    rm -f "$CONVERTED_FILES_DIR/${base}_"*.csv

    if ! python3 - "$input_file" "$CONVERTED_FILES_DIR" "$base" <<'PYCODE'
import openpyxl, os, sys

# Parse args
if len(sys.argv) != 4:
    print("Error: expected 3 args (input, out_dir, base)", file=sys.stderr)
    sys.exit(1)

input_path, out_dir, base = sys.argv[1:]
delim = "ǂ"

# Attempt to load workbook
try:
    wb = openpyxl.load_workbook(input_path, data_only=True)
except Exception as e:
    print(f"Error: could not open '{input_path}': {e}", file=sys.stderr)
    sys.exit(1)

ws = wb.active

# Prepare file handles
paths = {
    'input'     : os.path.join(out_dir, f"{base}_input.csv"),
    'output'    : os.path.join(out_dir, f"{base}_output.csv"),
    'difficulty': os.path.join(out_dir, f"{base}_difficulty.csv"),
}

files = {}
for key, path in paths.items():
    try:
        files[key] = open(path, "w", encoding="utf-8", newline="")
    except Exception as e:
        print(f"Error: cannot write to '{path}': {e}", file=sys.stderr)
        sys.exit(1)

# Iterate rows
for row in ws.iter_rows(values_only=True):
    # Normalize each column (empty if missing)
    c0 = row[0] if len(row) > 0 and row[0] is not None else ""
    c1 = row[1] if len(row) > 1 and row[1] is not None else ""
    c2 = row[2] if len(row) > 2 and row[2] is not None else ""
    for val, key in ((c0, 'input'), (c1, 'output'), (c2, 'difficulty')):
        text = str(val).replace("\r\n", "\n")
        files[key].write(text + delim + "\n")

# Close
for f in files.values():
    f.close()

sys.exit(0)
PYCODE
    then
        echo "Error: failed to convert '$input_file'" >&2
        return 1
    fi
}
