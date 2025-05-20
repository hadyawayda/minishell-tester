#!/usr/bin/env bash

parsing_tester_menu() {
    TEST_TYPE="parsing"

    while true; do
        clear
        echo -e "${BLUE}----- Parsing Tester -----${NC}"
        echo -e "${GREEN}d) ${CYAN}Parsing (50 Cases)${GREEN}"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
        echo
        read -n 1 -rp "Select an option: " choice

        case $choice in
            d) execute_test "../parsing/parsing.xlsx"                    ;;
            f) break ;;
            *) echo "Invalid option."; sleep 1 ;;
        esac
    done
}
