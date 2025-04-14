#!/usr/bin/env bash

parse_leaks() {
  local leaks_output="$1"
  
  # Extract each category line from Valgrind output (case-insensitive)
  local def_line ind_line pos_line still_line
  def_line=$(echo "$leaks_output" | grep -i "definitely lost:")
  ind_line=$(echo "$leaks_output" | grep -i "indirectly lost:")
  pos_line=$(echo "$leaks_output" | grep -i "possibly lost:")
  still_line=$(echo "$leaks_output" | grep -i "still reachable:")

  # Extract the leaked byte count from each line.
  # We assume the format is: "Category: <bytes> bytes in <blocks> blocks"
  local def_bytes ind_bytes pos_bytes still_bytes

  def_bytes=$(echo "$def_line" | sed -n 's/.*definitely lost:[[:space:]]*\([0-9,]\+\) bytes.*/\1/p' | head -n 1 | tr -d ',')
  ind_bytes=$(echo "$ind_line" | sed -n 's/.*indirectly lost:[[:space:]]*\([0-9,]\+\) bytes.*/\1/p' | head -n 1 | tr -d ',')
  pos_bytes=$(echo "$pos_line" | sed -n 's/.*possibly lost:[[:space:]]*\([0-9,]\+\) bytes.*/\1/p' | head -n 1 | tr -d ',')
  still_bytes=$(echo "$still_line" | sed -n 's/.*still reachable:[[:space:]]*\([0-9,]\+\) bytes.*/\1/p' | head -n 1 | tr -d ',')
  
  # Set default values if empty
  def_bytes=${def_bytes:-0}
  ind_bytes=${ind_bytes:-0}
  pos_bytes=${pos_bytes:-0}
  still_bytes=${still_bytes:-0}

  # If all categories are zero, output nothing.
  if (( def_bytes == 0 && ind_bytes == 0 && pos_bytes == 0 && still_bytes == 0 )); then
    return 0
  fi

  # Build the summary string for categories with nonzero leaks.
  local summary=""
  if (( def_bytes > 0 )); then
    summary+="[definitely lost:\t${def_bytes} bytes]\n"
  fi
  if (( ind_bytes > 0 )); then
    summary+="[indirectly lost:\t${ind_bytes} bytes]\n"
  fi
  if (( pos_bytes > 0 )); then
    summary+="[possibly lost:\t\t${pos_bytes} bytes]\n"
  fi
  if (( still_bytes > 0 )); then
    summary+="[still reachable:\t${still_bytes} bytes]\n"
  fi

  # Output the constructed summary.
  echo "$summary"
  return 0
}

run_one_case() {
  local cmd_block="$1" test_index="$2" valgrind_enabled="$3" file="$4"

  # 1) Compute expected output using bash
  local expected_output="$(echo -e "$cmd_block" | bash 2>&1)"

  # 2) Run your minishell on the same block
  local actual_output="$(echo -e "$cmd_block" | script -q -c "$ROOT_DIR/minishell" /dev/null 2>&1)"
  actual_output="$(clean_actual_output "$actual_output")"
  # echo -e "$actual_output" | cat -A
  echo -e $actual_output "\n" >> output.txt

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

clean_actual_output() {
  local raw_output="$1"
  local cleaned=""
  local IFS=$'\n'
  local line
  local line_number=0

  # Process the raw output line by line.
  for line in $raw_output; do
    ((line_number++))
    # Skip the command lines (assumed to be the first two)
    if (( line_number <= 2 )); then
      continue
    fi

    # When a line contains PROGRAM_PROMPT anywhere, remove it and everything following,
    # and stop processing further lines.
    if [[ "$line" == *"$PROGRAM_PROMPT"* ]]; then
      cleaned+="${line%%$PROGRAM_PROMPT*}"
      break
    fi

    # Otherwise, append the whole line.
    cleaned+="$line"$'\n'
  done

  # Output the cleaned result.
  # (This prints all output lines up to the first occurrence of PROGRAM_PROMPT.)
  printf "%s" "$cleaned" | strip_ansi_and_cr
}

strip_ansi_and_cr() {
  sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
}

run_valgrind_check() {
  local cmd_block="$1"
  echo -e "$cmd_block" | \
    valgrind --leak-check=full --suppressions=$CONFIG_DIR/ignore_readline.supp \
    "$ROOT_DIR/minishell" 2>&1
}

compare_outputs() {
  local expected="$1"
  local actual="$2"

  [[ "$expected" == *"syntax error"* && "$actual" == *"syntax error"* ]] ||
  [[ "$expected" == *"command not found"* && "$actual" == *"command not found"* ]] ||
  [[ "$expected" == *"No such file or directory"* && "$actual" == *"No such file or directory"* ]] ||
  [[ "$expected" == *"Is a directory"* && "$actual" == *"Is a directory"* ]] ||
  [[ "$expected" == *"invalid option"* && "$actual" == *"invalid option"* ]] ||
  [[ "$expected" == *"not a valid identifier"* && "$actual" == *"not a valid identifier"* ]] ||
  [[ "$expected" == *"numeric argument required"* && "$actual" == *"numeric argument required"* ]] ||
  [[ "$expected" == *"too many arguments"* && "$actual" == *"too many arguments"* ]] ||
  [[ "$expected" == *"ambiguous redirect"* && "$actual" == *"ambiguous redirect"* ]] ||
  [[ "$expected" == *"here-document at line 1 delimited by end-of-file"* &&
     "$actual" == *"here-document at line 1 delimited by end-of-file"* ]] ||
  [[ "$actual" == "$expected" ]]
}

determine_colors() {
  local overall_pass="$1"
  local leak_flag="$2"
  local debugging="$3"
  local -n _header_color=$4
  local -n _actual_color=$5

  if [[ "$debugging" == "1" ]]; then
    if $overall_pass; then
      _actual_color="${GREEN}"
      if [[ "$leak_flag" -eq 1 ]]; then
        _header_color="${YELLOW}"  # Correct output, but leaks
      else
        _header_color="${BLUE}"    # Correct output, no leaks
      fi
    else
      _actual_color="${RED}"
      if [[ "$leak_flag" -eq 1 ]]; then
        _header_color="${ORANGE}"  # Wrong output and leaks
      else
        _header_color="${BLUE}"    # Wrong output, no leaks
      fi
    fi
  else
    # DEBUGGING off, only header is colored
    if $overall_pass; then
      if [[ "$leak_flag" -eq 1 ]]; then
        _header_color="${ORANGE}"  # Correct output but with leaks
      else
        _header_color="${GREEN}"   # Perfect pass
      fi
    else
      _header_color="${RED}"       # Incorrect output
    fi
  fi
}

print_test_result() {
  local test_index="$1"
  local cmd_block="$2"
  local expected="$3"
  local actual="$4"
  local leaks="$5"
  local leak_summary="$6"
  local header_color="$7"
  local expected_color="$8"
  local actual_color="$9"

  echo -ne "${header_color}Test #$test_index"
  (( test_index > 9 )) && echo -ne "\t" || echo -ne "\t\t"
  echo -e "[$cmd_block]"

  if [[ "$DEBUGGING" == "1" ]]; then
    echo -e "${expected_color}Expected:\t[${expected}]"
    echo -e "${actual_color}Actual:\t\t[${actual}]"
  fi

  if [[ "$valgrind_enabled" == "1" && "$leaks" -ne 0 ]]; then
    echo -ne "${YELLOW}Leaks Summary:\t$leak_summary"
    [[ "$DEBUGGING" == "1" ]] && echo
  fi

  [[ "$DEBUGGING" == "1" ]] && echo
}

log_failure_if_needed() {
  local pass="$1"
  local file="$2"
  local test_index="$3"
  local cmd_block="$4"
  local expected="$5"
  local actual="$6"
  local leak_flag="$7"
  local leak_summary="$8"

  if ! $pass; then
    {
      echo -ne "$file test #$test_index:\t\t[$cmd_block]"
      echo
      [[ "$DEBUGGING" == "1" ]] && {
        echo -e "Expected:\t\t[$expected]"
        echo -e "Actual:\t\t\t[$actual]"
      }
      [[ "$valgrind_enabled" == "1" && "$leak_flag" -ne 0 ]] && echo -e "Leaks Summary:\t\t$leak_summary"
      echo
    } >> "$FAILED_SUMMARY_FILE"
  fi
}

execute_test_cases() {
  local input_csv="$1"
  local valgrind_enabled="$2"
  local test_index=1
  local delimiter="ǂ"
  local file=$(basename "$3" .xlsx)

  # Open the input CSV using file descriptor 3
  exec 3< "$input_csv"

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
    
    run_one_case "$full_block" "$test_index" "$valgrind_enabled" "$file"
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
        continue
      fi

      # If we didn't accumulate anything, we might be at EOF
      if [[ -z "$test_block" ]]; then
        break
      fi

      TOTAL_TESTS=$((TOTAL_TESTS+1))

      # For each line, remove leading "$> " if present
      # We'll do that for the entire block
      local cleaned_block="$(echo "$test_block" | sed 's/^\$> //')"

      # run the entire block as one case
      run_one_case "$cleaned_block" "$test_index" "$valgrind_enabled" "$file"
      ((test_index++))
    done
  fi

  exec 3<&-
}
