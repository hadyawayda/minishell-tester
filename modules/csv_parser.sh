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

python_csv_convert() {
    local base_dir="$1"
    local base_name="$2"
    local delimiter="$3"

    python3 <<EOF
import csv
base_dir = "$base_dir"
delimiter = "$delimiter"
base_name = "$base_name"

with open(f"{base_dir}/{base_name}_expected_input.csv") as infile, open(f"{base_dir}/{base_name}_input.csv", "w") as outfile:
    for row in csv.reader(infile):
        outfile.write((row[0] if row else "") + delimiter + "\n")

with open(f"{base_dir}/{base_name}_expected_output.csv") as infile, open(f"{base_dir}/{base_name}_output.csv", "w") as outfile:
    for row in csv.reader(infile):
        outfile.write((row[0] if row else "") + delimiter + "\n")
EOF
}

# Updated convert_excel_to_csv function leveraging global paths and checking for column 2
convert_excel_to_csv() {
    local input_file="$1"
    local base_name
    base_name=$(basename "$input_file" .xlsx)
    local delimiter="ǂ"
    
    mkdir -p "$CONVERTED_FILES_DIR" || { echo "Failed to create $CONVERTED_FILES_DIR"; return 1; }

    rm -f "$CONVERTED_FILES_DIR/${base_name}_input.csv" \
          "$CONVERTED_FILES_DIR/${base_name}_output.csv" \
          "$CONVERTED_FILES_DIR/${base_name}_expected_input.csv" \
          "$CONVERTED_FILES_DIR/${base_name}_expected_output.csv"
    
    # Convert the entire Excel file to CSV once
    local full_csv
    full_csv=$(in2csv "$input_file")
    
    # Determine the number of columns from the header line
    local header
    header=$(echo "$full_csv" | head -n 1)
    local num_columns
    num_columns=$(echo "$header" | awk -F, '{print NF}')
    
    # Extract column 1 always
    echo "$full_csv" | csvcut -c 1 > "$CONVERTED_FILES_DIR/${base_name}_expected_input.csv"
    
    # Extract column 2 only if it exists; otherwise, create an empty file
    if [ "$num_columns" -ge 2 ]; then
        echo "$full_csv" | csvcut -c 2 > "$CONVERTED_FILES_DIR/${base_name}_expected_output.csv"
    else
        > "$CONVERTED_FILES_DIR/${base_name}_expected_output.csv"
    fi

    # Call the external Python conversion function
    python_csv_convert "$CONVERTED_FILES_DIR" "$base_name" "$delimiter"

    # Clean up temporary files
    rm "$CONVERTED_FILES_DIR/${base_name}_expected_input.csv" "$CONVERTED_FILES_DIR/${base_name}_expected_output.csv"
}
