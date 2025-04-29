#!/usr/bin/env bash

run_one_case() {
  local cmd_block="$1" expected_output="$2" test_index="$3" valgrind_enabled="$4" file="$5"

  # 1) Compute expected output using bash
  cd "$EXECUTION_DIR"

  # 2) Run your minishell on the same block
  if [[ "${TEST_TYPE:-}" == "program" && ( "$cmd_block" == *"| cat -e"* || "$cmd_block" == *"|"* ) ]]; then
    actual_output="$(echo -e "$cmd_block" | script -q -c "$ROOT_DIR/$EXECUTABLE_NAME" /dev/null 2>&1 | strip_ansi_and_cr)"
    actual_output="$(clean_interactive_output "$actual_output")"
  else
    actual_output="$(echo -e "$cmd_block" | "$ROOT_DIR/$EXECUTABLE_NAME" 2>&1 | strip_ansi_and_cr)"
    actual_output="$(clean_actual_output "$actual_output")"
  fi

  # 3) Trim empty lines
  actual_output="$(printf '%s\n' "$actual_output" | sed '/^$/d')"

  # 4) If valgrind is enabled, capture the full leaks summary.
  local leaks_output="No leaks detected"
  local leak_summary=""
  local leak_flag=0
  if [[ "$valgrind_enabled" == "1" ]]; then
    leaks_output="$(run_valgrind_check "$cmd_block")"
    leak_summary=$(parse_leaks "$leaks_output")
    [[ -n "$leak_summary" ]] && leak_flag=1
  fi

  # 5) Compare outputs (partial match for errors, or exact match)
  local pass_output=false
  compare_outputs "$expected_output" "$actual_output" && pass_output=true

  local pass_leak=false
  [[ "$valgrind_enabled" == "0" || "$leak_flag" -eq 0 ]] && pass_leak=true

  local overall_pass=false
  $pass_output && $pass_leak && overall_pass=true

  # 6) Colorize output results
  local header_color expected_color="${GREEN}" actual_color
  determine_colors "$overall_pass" "$leak_flag" "$DEBUGGING" header_color actual_color

  # 7) Print results
  print_test_result "$test_index" "$cmd_block" "$expected_output" "$actual_output" "$leak_flag" "$leak_summary" "$header_color" "$expected_color" "$actual_color"
  $overall_pass && PASSED_TESTS=$((PASSED_TESTS + 1))

  # 8) Log failure details if the test failed.
  log_failure_if_needed "$overall_pass" "$file" "$test_index" "$cmd_block" "$expected_output" "$actual_output" "$leak_flag" "$leak_summary"
}

execute_test_cases() {
  local input_csv="$1"
  local output_csv="$4"
  local diff_csv="$5"
  local valgrind_enabled="$2"
  local test_index=1
  local delimiter="ǂ"
  local file=$(basename "$3" .xlsx)

  # Open the input CSV using file descriptor 3
  exec 3< "$input_csv"
  [[ "$TEST_TYPE" == "tokenization" ]] && exec 4< "$output_csv"
  exec 5< "$diff_csv"

  if [[ "${CUMULATIVE_TESTING:-0}" == "1" ]]; then
    # CUMULATIVE TESTING MODE: run the entire file as one big test block.
    local full_block=""
    while IFS= read -r line <&3; do
      # Skip certain cases if bonus is off
      if [[ "$line" == *"sleep"* ]] || 
         [[ "${BONUS_TESTING_ENABLED:-0}" -eq 0 && 
         ("$line" == *"*"* || "$line" == *"&&"* || "$line" == *"||"* || "$line" == *"("* || "$line" == *")"*) ]]; then
        continue
      fi

      # Remove trailing delimiter if present
      line="${line%$delimiter}"
      full_block+="${line}"$'\n'
    done

    # Strip leading $> if present on each line
    full_block="$(echo "$full_block" | sed 's/^\$> //')"

    TOTAL_TESTS=$((TOTAL_TESTS+1))
    
    local expected_output="$(echo -e "$full_block" | bash 2>&1)"

    run_one_case "$full_block" "$expected_output" "$test_index" "$valgrind_enabled" "$file"
  else
    while true; do
      local test_block=""
      local skip_case=false

      # Read lines until we find one that ends with the delimiter
      while IFS= read -r line <&3; do
        # If we hit EOF with no line, break out
        if [[ -z "$line" && -z "$test_block" ]]; then
          break 2  # break outer while
        fi

        if  [[ "$line" == *"sleep"* ]] || 
            [[ "${BONUS_TESTING_ENABLED:-0}" -eq 0 && 
            ("$line" == *"*"* || "$line" == *"&&"* || "$line" == *"||"* || "$line" == *"("* || "$line" == *")"*) ]]; then
          skip_case=true
          break
        fi

        if [[ "$line" == *"$delimiter" ]]; then
          # Remove the trailing delimiter
          line="${line%$delimiter}"

          # Append this final line to test_block
          test_block+="$line"$'\n'
          break
        else
          test_block+="$line"$'\n'
        fi
      done

      if $skip_case; then
        if [[ "${TEST_TYPE:-}" == "tokenization" ]]; then
          read -r _dummy <&4
        fi
        continue
      fi

      # If we didn't accumulate anything, we might be at EOF
      if [[ -z "$test_block" ]]; then
        break
      fi

      local difficulty
      read -r difficulty <&5
      difficulty="${difficulty%$delimiter}"

      # 1) Skip if no difficulty column
      if [[ -z "$difficulty" ]]; then
        (( test_index++ ))
        continue
      fi

      # 2) If CASE_DIFFICULTY > 0 and this case is harder, skip
      if (( CASE_DIFFICULTY != 0 && difficulty > CASE_DIFFICULTY )); then
        (( test_index++ ))
        continue
      fi

      TOTAL_TESTS=$((TOTAL_TESTS+1))

      # For each line, remove leading "$> " if present
      # We'll do that for the entire block
      local cleaned_block="$(echo "$test_block" | sed 's/^\$> //')"

      # compute expected_output
      local expected_output
      if [[ "${TEST_TYPE:-}" == "tokenization" ]]; then
        read -r expected_output <&4
        expected_output=${expected_output%ǂ}
      else
          expected_output="$(echo -e "$cleaned_block" | bash 2>&1)"
      fi

      # run the entire block as one case
      run_one_case "$cleaned_block" "$expected_output" "$test_index" "$valgrind_enabled" "$file"
      ((test_index++))
    done
  fi

  exec 3<&-
  [[ -n "${output_csv:-}" ]] && exec 4<&-
}
