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
  local cmd_block="$1"
  local test_index="$2"
  local valgrind_enabled="$3"
  local file="$4"

  # 1) Compute expected output using bash
  local expected_output="$(echo -e "$cmd_block" | bash 2>&1)"

  # 2) Run your minishell on the same block
  local actual_output="$(echo -e "$cmd_block" | "$ROOT_DIR/minishell" 2>&1)"

  # 3) Strip ANSI color codes and prompt lines
  actual_output="$(
    echo "$actual_output" | sed -E "
      s/\x1b\[[0-9;]*m//g;   # remove ANSI color codes
      1d;                   # remove the first line
      s|${PROGRAM_PROMPT//|\\|}.*||
    "
  )"

  # 4) If valgrind is enabled, capture the full leaks summary.
  local leaks_output="No leaks detected"
  if [[ "$valgrind_enabled" == "1" ]]; then
    leaks_output="$(echo -e "$cmd_block" | \
      valgrind --leak-check=full --suppressions=$TESTER_DIR/config/ignore_readline.supp \
      "$ROOT_DIR/minishell" 2>&1)"
    local leak_summary=$(parse_leaks "$leaks_output")
    local leak_flag=0
    if [[ -n "$leak_summary" ]]; then
      leak_flag=1
    fi
  fi

  # 5) Compare outputs (partial match for errors, or exact match)
  local pass_output=false

  if [[ "$expected_output" == *"syntax error"* && "$actual_output" == *"syntax error"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"command not found"* && "$actual_output" == *"command not found"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"No such file or directory"* && "$actual_output" == *"No such file or directory"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"Is a directory"* && "$actual_output" == *"Is a directory"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"invalid option"* && "$actual_output" == *"invalid option"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"not a valid identifier"* && "$actual_output" == *"not a valid identifier"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"numeric argument required"* && "$actual_output" == *"numeric argument required"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"too many arguments"* && "$actual_output" == *"too many arguments"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"ambiguous redirect"* && "$actual_output" == *"ambiguous redirect"* ]]; then
    pass_output=true
  elif [[ "$expected_output" == *"here-document at line 1 delimited by end-of-file"* && "$actual_output" == *"here-document at line 1 delimited by end-of-file"* ]]; then
    pass_output=true
  elif [[ "$actual_output" == "$expected_output" ]]; then
    pass_output=true
  fi

  local pass_leak=false
  if [[ "$valgrind_enabled" == "0" ]] || [[ "$leak_flag" -eq 0 ]]; then
    pass_leak=true
  fi

  local overall_pass=false
  if $pass_output && $pass_leak; then
    overall_pass=true
  fi

  # 6) Colorize output results
  local header_color expected_color actual_color
  if [[ "$DEBUGGING" == "1" ]]; then
    if $overall_pass; then
      # Output correct, debugging on.
      if [[ "$leak_flag" -eq 1 ]]; then
        header_color="${YELLOW}"    # leaks present -> header becomes YELLOW
        expected_color="${GREEN}"   # expected remains GREEN
        actual_color="${GREEN}"    # actual becomes YELLOW
      else
        header_color="${BLUE}"      # no leaks -> header is BLUE
        expected_color="${GREEN}"   # expected remains GREEN
        actual_color="${GREEN}"     # actual becomes GREEN
      fi
    else
      # Output not correct, debugging on.
      if [[ "$leak_flag" -eq 1 ]]; then
        header_color="${ORANGE}"    # leaks present -> header becomes ORANGE
        expected_color="${GREEN}"   # expected remains GREEN
        actual_color="${RED}"    # actual becomes YELLOW
      else
        header_color="${BLUE}"      # no leaks -> header remains BLUE
        expected_color="${GREEN}"   # expected remains GREEN
        actual_color="${RED}"       # actual becomes RED
      fi
    fi
  else
    # DEBUGGING off, only header is printed.
    if $overall_pass; then
      if [[ "$leak_flag" -eq 1 ]]; then
        header_color="${ORANGE}"    # correct output, but leaks: header = YELLOW
      else
        header_color="${GREEN}"     # correct output, no leaks: header = GREEN
      fi
    else
	header_color="${RED}"       # incorrect output, no leaks: header = RED
    fi
  fi

  # 7) Print results
  if $overall_pass; then
    echo -ne "${header_color}"
    echo -ne "Test #$test_index"
    if (( test_index > 9 )); then
      echo -ne "\t"
    else
      echo -ne "\t\t"
    fi
    echo -e "[${cmd_block}]"
    PASSED_TESTS=$((PASSED_TESTS+1))
  else
    echo -ne "${header_color}"
    echo -ne "Test #$test_index"
    if (( test_index > 9 )); then
      echo -ne "\t"
    else
      echo -ne "\t\t"
    fi
    echo -e "[${cmd_block}]"
  fi

  if [[ "$DEBUGGING" == "1" ]]; then
    echo -e "${expected_color}Expected:\t[${expected_output}]"
    echo -e "${actual_color}Actual:\t\t[${actual_output}]"
  fi

  if [[ "$valgrind_enabled" == "1" && "$leak_flag" -ne 0 ]]; then
    echo -ne "${YELLOW}Leaks Summary:\t${leak_summary}"
    if [[ "$DEBUGGING" == "1" ]]; then
      echo
    fi
  fi

  if [[ "$DEBUGGING" == "1" ]]; then
    echo
  fi

  # 8) Log failure details if the test failed.
  if ! $overall_pass; then
    {
	    echo -ne "$file test #$test_index:"
      if (( test_index > 9 )); then
        echo -ne "\\t"
      else
        echo -ne "\\t"
      fi
      echo -e "[${cmd_block}]"
      if [[ "$DEBUGGING" == "1" ]]; then
        echo -e "Expected:\\t\\t[${expected_output}]"
        echo -e "Actual:\\t\\t\\t[${actual_output}]"
      fi
      if [[ "$valgrind_enabled" == "1" && "$leak_flag" -ne 0 ]]; then
        echo -ne "Leaks Summary:\t\t${leak_summary}"
      fi
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

  exec 3<&-
}
