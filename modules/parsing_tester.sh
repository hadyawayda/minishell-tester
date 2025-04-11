#!/usr/bin/env bash

run_tokenization_tests() {
    while true; do
        clear
        echo -e "${BLUE}----- Tokenization Tester -----${NC}"
        echo -e "${GREEN}a) ${CYAN}Run All Cases"
        echo -e "${GREEN}1) Echo Cases"
        echo -e "2) \$ expansions"
        echo -e "3) Quotations"
        echo -e "4) Piping"
        echo -e "5) Redirections"
        echo -e "6) AND (&&) / OR (||)"
        echo -e "7) Wildcard"
        echo -e "8) Export / Env"
        echo -e "9) Exit Status Handling"
        echo -e "10) Signals Handling"
        echo -e "11) Mix / Complex Cases${NC}"
        echo -e "${ORANGE}f) Return to Tokenization Menu${GREEN}"
        echo -e
        read -rp "Select an option: " choice

        case $choice in
            a)echo -e "${BLUE}Running all test cases...${GREEN}" ;;
            1) file="test_files/parsing_echo.xlsx" ;;
            2) file="test_files/parsing_dollar_expansion.xlsx" ;;
            3) file="test_files/parsing_quotations.xlsx" ;;
            4) file="test_files/parsing_piping.xlsx" ;;
            5) file="test_files/parsing_redirections.xlsx" ;;
            6) file="test_files/parsing_and_or.xlsx" ;;
            7) file="test_files/parsing_wildcard.xlsx" ;;
            8) file="test_files/parsing_export_env.xlsx" ;;
            9) file="test_files/parsing_exit_status.xlsx" ;;
            10) file="test_files/parsing_signals.xlsx" ;;
            11) file="test_files/parsing_complex_cases.xlsx" ;;
            f) break ;;
            *) echo "Invalid option." ; continue ;;
        esac

        run_test_case "$file"
    done
}

parsing_tester_menu() {
    clear
	echo "Upcoming feature!"
    echo -e
    read -n 1 -rp "Press any key to continue..." ;
    return 0
    
    while true; do
        clear
        echo -e "${BLUE}----- Parsing Tester -----${NC}"
        echo -e "${GREEN}1) Run parsing tests"
        echo -e "2) Set parsing file path"
        echo -e "3) Set token struct header path${NC}"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
        echo -e
        read -rp "Option: " choice
        
        case $choice in
            1) run_parsing_tests ;; 
            2) read -rp "Enter parsing file path: " TOKEN_FILE ;;
            3) read -rp "Enter struct header path: " TOKEN_STRUCT ;;
            f) break ;;
            *) echo "Invalid option." ;;
        esac
    done
}
