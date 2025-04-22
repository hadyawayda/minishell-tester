#!/usr/bin/env bash


run_all_tokenization_cases () {
	#########################
	# Configuration
	#########################
	
	INPUT_FILE="$TEST_FILES_DIR/tokenization/tokenizer_cases.txt"
	EXPECTED_FILE="$TEST_FILES_DIR/tokenization/tokenizer_cases_expected_output.txt"
	MINISHELL="$ROOT_DIR/minishell_test"  # Adjust if your binary name differs
	
	if [[ ! -x "$MINISHELL" ]]; then
		cd ..
		make te
		cd minishell-tester
	fi

	clear

	#########################
	# Checks
	#########################
	if [[ ! -x "$MINISHELL" ]]; then
	echo "Error: $MINISHELL not found or not executable."
	exit 1
	fi

	if [[ ! -f "$INPUT_FILE" ]]; then
	echo "Error: $INPUT_FILE not found."
	exit 1
	fi

	if [[ ! -f "$EXPECTED_FILE" ]]; then
	echo "Error: $EXPECTED_FILE not found."
	exit 1
	fi

	#########################
	# Script Logic
	#########################
	test_index=1
	passed_tests=0
	total_tests=0

	# Open file descriptors for reading:
	exec 3<"$INPUT_FILE"
	exec 4<"$EXPECTED_FILE"

	while true
	do
	# Read next command from tokenizer_cases.txt
	IFS= read -r cmd <&3 || break  # if we can't read more lines, break
	# Each test has exactly two expected lines + a blank line to skip
	IFS= read -r exp_line1 <&4 || break
	IFS= read -r exp_line2 <&4 || break

	# Try to skip one blank line (if it exists) so the next test doesn't consume it
	# If there's no blank line, it won't hurt—just stops if there's text or EOF.
	read -r maybe_blank <&4
	# if [[ -n "$maybe_blank" ]]; then
	# That wasn't an empty line; we "consumed" something that
	# might be your next test's first line. 
	# So we put it back into the stream for the next read.
	# Bash trick: create a temp file or just store it in a variable and re-feed it.
	# Easiest approach: we store it in a variable "BACKLINE" and 
	# re-inject it into FD #4 at the top of the loop. 
	# For simplicity, we won't do that here, but see note below if needed.
	#
	# If you'd rather not do any pushback logic, 
	# comment out this block and ensure your expected file truly has a blank line 
	# after every two lines of expected output.
	# echo "$maybe_blank" > .line_tmp
	# exec 4< <(cat .line_tmp; cat "$EXPECTED_FILE" | tail -n +$(($(grep -nxF "$maybe_blank" "$EXPECTED_FILE" | cut -d: -f1)+1)))
	# This hack reopens FD 4 with the line reinserted.
	# fi

	((total_tests++))

	# Run minishell with the command. Capture the output in a variable.
	# Adjust how many lines we read if your minishell prints more.
	actual_output="$("$MINISHELL" "$cmd" 2>&1)"

	# We expect exactly two lines in the output we care about:
	actual_line1="$(echo "$actual_output" | sed -n '1p')"
	actual_line2="$(echo "$actual_output" | sed -n '2p')"

	# Compare them
	pass_line1=false
	pass_line2=false
	[[ "$actual_line1" == "$exp_line1" ]] && pass_line1=true
	[[ "$actual_line2" == "$exp_line2" ]] && pass_line2=true

	# Determine overall pass/fail
	if $pass_line1 && $pass_line2; then
	overall_pass=true
	((passed_tests++))
	else
	overall_pass=false
	fi

	# Print results with colors
	if $overall_pass; then
	echo -e "${GREEN} Test #$test_index${NC}   Command:  [${cmd}]"
	else
	echo -e "${RED} Test #$test_index${NC}   Command:  [${cmd}]"
	fi

	# Line 1
	if $pass_line1; then
	echo -e "${GREEN}Line1:${NC}     Expected: [${GREEN}${exp_line1}${NC}] Actual: [${GREEN}${actual_line1}${NC}]"
	else
	echo -e "${RED}Line1:${NC}     Expected: [${GREEN}${exp_line1}${NC}],  Actual: [${RED}${actual_line1}${NC}]"
	fi

	# Line 2
	if $pass_line2; then
	echo -e "${GREEN}Line2:${NC}     Expected: [${GREEN}${exp_line2}${NC}] Actual: [${GREEN}${actual_line2}${NC}]"
	else
	echo -e "${RED}Line2:${NC}     Expected: [${GREEN}${exp_line2}${NC}],  Actual: [${RED}${actual_line2}${NC}]"
	fi

	echo
	((test_index++))

	done

	rm -f .line_tmp 2>/dev/null

	echo -e "${GREEN}All done.${NC}"
	echo -e "Passed ${GREEN}${passed_tests}${NC} out of ${total_tests} tests."

	echo -e
	read -n 1 -rsp "Press any key to continue"

	cd ..
	make tclean
}
