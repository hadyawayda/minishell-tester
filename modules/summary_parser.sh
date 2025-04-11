#!/usr/bin/env bash

display_failed_summary() {
  if [[ ! -s "$FAILED_SUMMARY_FILE" ]]; then
    echo "No failed test cases to report."
    return
  fi

  echo -e "${CYAN}Summary of failed test cases\n"

  # We'll read the file line by line from FD 3
  exec 3< "$FAILED_SUMMARY_FILE"

  local state="outside"
  local line
  local debug="${DEBUGGING:-0}"

  if (( debug == 0 )); then
    ############################################################
    # DEBUGGING=0 => print EVERY line in RED, ignore chunking
    ############################################################
    while IFS= read -r line <&3; do
      echo -e "${RED}$line"
    done
  else
    ############################################################
    # DEBUGGING=1 => chunk lines into header/expected/actual
    ############################################################
    while IFS= read -r line <&3; do
      # If line matches:  ^[^[:space:]]+[[:space:]]+test[[:space:]]+#[0-9]+:
      # => header (blue)
      if [[ "$line" =~ ^[^[:space:]]+[[:space:]]+test[[:space:]]+#[0-9]+: ]]; then
        state="header"
        echo -e "${BLUE}$line"
        continue
      fi

      # If line starts with "Expected:", green
      if [[ "$line" =~ ^Expected: ]]; then
        state="expected"
        echo -e "${GREEN}$line"
        continue
      fi

      # If line starts with "Actual:", red
      if [[ "$line" =~ ^Actual: ]]; then
        state="actual"
        echo -e "${RED}$line"
        continue
      fi

	  # If line starts with Leaks, yellow
	  if [[ "$line" =~ ^Leaks ]]; then
		state="leaks"
		echo -e "${YELLOW}$line"
		continue
	  fi

      # Otherwise, color depends on current state
      case "$state" in
        header)
          echo -e "${BLUE}$line"
          ;;
        expected)
          echo -e "${GREEN}$line"
          ;;
        actual)
          echo -e "${RED}$line"
          ;;
		leaks)
		  echo -e "${YELLOW}$line"
		  ;;
      esac
    done
  fi

  exec 3<&-

  echo -e "${GREEN}"
  read -n 1 -rsp "Press any key to continue..."
  echo
}
