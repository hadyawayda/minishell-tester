#!/usr/bin/env bash

run_test_case() {
    local file="$1"
    local no_pause="$2"
    if [[ "$no_pause" != "true" ]]; then
	    clear
    fi

    echo -e "${BLUE}Now testing $(basename "$file" .xlsx) cases:${BLUE}\\n"

    local filename_base=$(basename "$file" .xlsx)

    local input_csv="$CONVERTED_FILES_DIR/${filename_base}_input.csv"
    local output_csv="$CONVERTED_FILES_DIR/${filename_base}_output.csv"

    # Convert Excel to CSV if needed
    if [[ ! -f "$input_csv" || ! -f "$output_csv" ]]; then
        convert_excel_to_csv "$(realpath "$file")" || return 1
    fi

    # Confirm CSV files exist
    if [[ ! -f "$input_csv" || ! -f "$output_csv" ]]; then
        echo -e "${RED}CSV files missing after conversion.${NC}"
        return 1
    fi

    # Execute the test cases (assuming execute_test_cases is defined elsewhere)
    execute_test_cases "$input_csv" "$VALGRIND_ENABLED" "$file"

    if [[ "$no_pause" != "true" ]]; then
        echo -ne "\\n"
        echo -e "${CYAN}All $filename_base cases done."
        echo -e "Passed $PASSED_TESTS out of $TOTAL_TESTS tests."
    fi
}

run_all_cases() {
    local test_dir="$1"
    local no_pause="$2"

    clear
    
    local files=("$test_dir"/*.xlsx)
    if [[ "${files[0]}" == "$test_dir/*.xlsx" || ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}\\nNo test files found in '$test_dir'.${NC}"
        return 1
    fi

    for file in "${files[@]}"; do
		local filename_base=$(basename "$file" .xlsx)
        run_test_case "$file" "$no_pause"
        if [[ "$no_pause" != "true" ]]; then
            PASSED_TESTS=0
            TOTAL_TESTS=0
			echo -e "${GREEN}"
			read -n 1 -rsp "Would you like to have a summary of the $filename_base failed test cases? (y/n/quit) " response
			if [[ "$response" =~ ^[Yy]$ ]]; then
				echo
            	clear
				# Display the failed summary for the basename of a file
				display_failed_summary "$filename_base"
            elif [[ "$response" =~ ^[Nn]$ ]]; then
                continue
            else
                break
			fi
        else
            echo
        fi
    done
}

execute_test() {
    PASSED_TESTS=0
    TOTAL_TESTS=0
    local test_type="$1"
    local test_arg="$2"
    local no_pause="$3"
    local original_dir="$(pwd)"
    local test_dir

    rm -rf "$TESTER_FILES_DIR"
	mkdir -p "$FAILED_TESTS_SUMMARY_DIR"

	# Ensure we start with an empty summary file.
	> "$FAILED_SUMMARY_FILE"

    # Determine test directory based on test type
    if [[ "$test_type" == "program" ]]; then
         test_dir="$PROGRAM_TEST_DIR"
    elif [[ "$test_type" == "tokenization" ]]; then
         test_dir="$TOKENIZATION_TEST_DIR"
    else
         echo "Invalid test type: $test_type"
         return 1
    fi

    # Create and enter the isolated execution directory
    mkdir -p "$EXECUTION_DIR"
    mkdir -p "$BASH_EXECUTION_DIR"
    mkdir -p "$CONVERTED_FILES_DIR"
    cp "$ROOT_DIR/minishell" "$EXECUTION_DIR"
    cp "$ROOT_DIR/minishell" "$BASH_EXECUTION_DIR"
    chmod +x $EXECUTION_DIR/minishell
    chmod +x $BASH_EXECUTION_DIR/minishell
    cd "$EXECUTION_DIR" || { echo "Cannot enter execution directory"; return 1; }

    if [[ "$test_arg" == "all" ]]; then
        run_all_cases "$test_dir" "$no_pause"
        if [[ "$no_pause" == "true" ]]; then
            echo -e "${BLUE}All done."
            echo -e "Passed $PASSED_TESTS out of $TOTAL_TESTS tests."
			echo -e "${GREEN}"
			read -n 1 -rsp "Would you like to have a summary of the failed test cases? (y/n) " response
			if [[ "$response" =~ ^[Yy]$ ]]; then
				echo
            	clear
				display_failed_summary "all"
			fi
        fi
    else
        local file="$test_dir/$test_arg"
        if [[ ! -f "$file" ]]; then
            echo -e "${RED}Test file '$file' not found.${NC}"
            cd "$original_dir" || exit
            return 1
        fi
        run_test_case "$file" "$no_pause"
		local file_name=$(basename "$file" .xlsx)
		echo -e "${GREEN}"
		read -n 1 -rsp "Would you like to have a summary of the failed $file_name cases? (y/n) " response
		if [[ "$response" =~ ^[Yy]$ ]]; then
			echo
			clear
			display_failed_summary "$file_name"
		fi
    fi

    # Return to original directory and clean up the tester_files directory
    cd "$original_dir" || exit
	
	# Remove the execution directory
    rm -rf "$TESTER_FILES_DIR"
}
