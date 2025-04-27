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
  # if (( def_bytes == 0 && ind_bytes == 0 && pos_bytes == 0 && still_bytes == 0 )); then
  #   return 0
  # fi

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

clean_interactive_output() {
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
  printf "%s" "$cleaned"
}

strip_ansi_and_cr() {
  sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
}

clean_actual_output() {
  local raw_output="$1"
  echo "$raw_output" | sed -E "
    s/\x1b\[[0-9;]*m//g;
    1d;
    s|${PROGRAM_PROMPT//|\\|}.*||
  "
}

run_valgrind_check() {
  local cmd_block="$1"
  echo -e "$cmd_block" | \
    valgrind --leak-check=full --suppressions=$CONFIG_DIR/ignore_readline.supp \
    "$ROOT_DIR/$EXECUTABLE_NAME" 2>&1
}

compare_outputs() {
  local expected="$1"
  local actual="$2"

  [[ "$expected" == *"syntax error"* && "$actual" == *"syntax error"* ]] ||
  [[ "$expected" == *"command not found"* && "$actual" == *"command not found"* ]] ||
  [[ "$expected" == *"No such file or directory"* && "$actual" == *"No such file or directory"* ]] ||
  [[ "$expected" == *"Is a directory"* && "$actual" == *"Is a directory"* ]] ||
  [[ "$expected" == *"Permission denied"* && "$actual" == *"Permission denied"* ]] ||
  [[ "$expected" == *"not set"* && "$actual" == *"not set"* ]] ||
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

  #─── Test header md_block, with multi‐line indent ──────────────────────
  printf "${header_color}Test #%s" "$test_index"
  if (( test_index > 9 )); then
    printf "\t"
  else
    printf "\t\t"
  fi
  # First line in brackets, indent all subsequent lines by 17 spaces
  printf "[%s]\n" "$(
    printf '%s\n' "$cmd_block" \
      | sed '1! s/^/                 /'
  )"

  if [[ "$DEBUGGING" == "1" ]]; then
    # split expected into lines, print first with label, others indented under the '['
    printf "${expected_color}Expected:\t"
    printf "[%s]\n" "$(printf '%s\n' "$expected" \
      | sed '1! s/^/                 /')"   # 16 spaces here to line up under the '['

    # same for actual (use two tabs so it lines up under the '[' in Actual:)
    printf "${actual_color}Actual:\t\t"
    printf "[%s]\n" "$(printf '%s\n' "$actual" \
      | sed '1! s/^/                 /')"
  fi

  if [[ "$valgrind_enabled" == "1" && "$leaks" -ne 0 ]]; then
    #─── Leaks Summary, interpret “\n” and indent subsequent lines ────────────
    printf "${YELLOW}Leaks Summary:\t"
    # %b will expand the \n into real newlines; sed adds 17-space indent on lines 2+
    printf '%b' "$leak_summary" | sed '1! s/^/                /'
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
      #─── Header + cmd_block (multi‐line indent) ────────────────────────────
      #─── Failure header + cmd_block, fixed‐width 16 chars ──────────────────────
      printf "%-23s [%s]\n" \
        "$file #$test_index:" \
        "$(
          printf '%s\n' "$cmd_block" \
            | sed '1! s/^/                         /'
        )"

      
      if [[ "$DEBUGGING" == "1" ]]; then
        # Expected
        printf "Expected:\t\t[%s]\n" "$(
          printf '%s\n' "$expected" | sed '1! s/^/                         /'
        )"
        # Actual
        printf "Actual:\t\t\t[%s]\n" "$(
          printf '%s\n' "$actual" | sed '1! s/^/                         /'
        )"
      fi

      # Leaks Summary (only when real leaks exist)
      if [[ "$valgrind_enabled" == "1" && "$leak_flag" -ne 0 ]]; then
        # Print label, then expand \n and indent lines 2+
        printf "Leaks Summary:\t\t"
        printf '%b' "$leak_summary" | sed '1! s/^/                        /'
        # ensure trailing newline
        echo
      fi

      # blank line between failures
      echo
    } >> "$FAILED_SUMMARY_FILE"
  fi
}

