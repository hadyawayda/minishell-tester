#!/usr/bin/env bash

tokenization_tester_menu() {
	while true; do
		clear
		echo -e "${BLUE}----- Tokenization Tester -----${NC}"
		echo -e "${GREEN}a) ${CYAN}Run All Cases (Interactive, 616+ Cases)"
        echo -e "${GREEN}b) ${CYAN}Run All Cases (No Pause, 616+ Cases)"
        echo -e "${GREEN}c) ${CYAN}Run All Cases (old version)"
        echo -e "${GREEN}1) Echo + Expansion (118 Cases)"
        echo -e "2) CD (56 Cases)"
        echo -e "3) Execution (52 Cases)"
        echo -e "4) Redirections (111 Cases)"
        echo -e "5) Exit Status (51 Cases)"
        echo -e "6) unset (52 Cases)"
        echo -e "7) Basic Cases + PWD (59 Cases)"
        echo -e "8) Complex Cases (10 Cases)"
        echo -e "9) env + export (Unstable) (117 Cases)"
		echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
		echo -e
		read -n 1 -rp "Select an option: " choice
		
		case $choice in
            a) execute_test "tokenization" "all" "false" ;;
            b) execute_test "tokenization" "all" "true" ;;
			c) run_all_tokenization_cases ;; 
            1) execute_test "tokenization" "quotations.xlsx";;
            2) execute_test "tokenization" "quotations_advanced.xlsx" ;;
            3) execute_test "tokenization" "execution.xlsx" ;;
            4) execute_test "tokenization" "redirections.xlsx" ;;
            5) execute_test "tokenization" "exit.xlsx" ;;
            6) execute_test "tokenization" "unset.xlsx" ;;
            7) execute_test "tokenization" "basic_cases.xlsx" ;;
            8) execute_test "tokenization" "complex_cases.xlsx" ;;
            9) execute_test "tokenization" "export.xlsx" ;;
			f) break ;;
			*) echo "Invalid option." ;;
		esac
	done
}
