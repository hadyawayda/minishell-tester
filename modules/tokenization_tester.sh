#!/usr/bin/env bash

tokenization_tester_menu() {
    while true; do
        clear
        echo -e "${BLUE}----- Tokenization Tester -----${GREEN}"
        echo -e "a) ${CYAN}Run All Cases"
        echo -e "${GREEN}1) Echo & \$ & Quotation Cases"
        echo -e "2) Piping"
        echo -e "3) Redirections"
        echo -e "4) AND (&&) / OR (||)"
        echo -e "5) Wildcard"
        echo -e "6) Export / Env"
        echo -e "7) Exit Status Handling"
        echo -e "8) Signals Handling"
        echo -e "9) Mix / Complex Cases${NC}"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
        echo -e
        read -n 1 -rp "Select an option: " choice
        
        case $choice in
            a) execute_test "tokenization" "all";;
            1) execute_test "tokenization" "echo.xlsx";;
            2) execute_test "tokenization" "piping.xlsx";;
            3) execute_test "tokenization" "redirections.xlsx";;
            4) execute_test "tokenization" "and_or.xlsx";;
            5) execute_test "tokenization" "wildcard.xlsx";;
            6) execute_test "tokenization" "export_env.xlsx";;
            7) execute_test "tokenization" "exit_status.xlsx";;
            8) execute_test "tokenization" "signals.xlsx";;
            9) execute_test "tokenization" "complex_cases.xlsx";;
            f) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}

tokenization_tester_menu() {
	while true; do
		clear
		echo -e "${BLUE}----- Tokenization Tester -----${NC}"
		echo -e "${GREEN}a) ${CYAN}Run All Cases (old version)"
		echo -e "${GREEN}1) Run partial tests"
		echo -e "2) Set tokenization file path"
		echo -e "3) Set token struct header path${NC}"
		echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
		echo -e
		read -n 1 -rp "Select an Option: " choice
		
		case $choice in
			a) run_all_tokenization_cases ;; 
			1) run_tokenization_tests ;; 
			2) read -rp "Enter tokenization file path: " TOKEN_FILE ;;
			3) read -rp "Enter struct header path: " TOKEN_STRUCT ;;
			f) break ;;
			*) echo "Invalid option." ;;
		esac
	done
}
