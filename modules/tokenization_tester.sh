#!/usr/bin/env bash

tokenization_tester_menu() {
    TEST_TYPE="tokenization"

    while true; do
        clear
        echo -e "${BLUE}----- Tokenization Tester -----${NC}"
        echo -e "${GREEN}a) ${CYAN}Run All Cases (Interactive, 616+ Cases)"
        echo -e "${GREEN}b) ${CYAN}Run All Cases (No Pause, 616+ Cases)"
        echo -e "${GREEN}c) ${CYAN}Run All Cases (Old Version)"
        echo -e "${GREEN}d) Expansion (450 Cases)"
        echo -e "1) Echo + Expansion (118 Cases)"
        echo -e "2) CD (56 Cases)"
        echo -e "3) Execution (52 Cases)"
        echo -e "4) Redirections (111 Cases)"
        echo -e "5) Exit Status (51 Cases)"
        echo -e "6) unset (52 Cases)"
        echo -e "7) Basic Cases + PWD (59 Cases)"
        echo -e "8) Complex Cases (10 Cases)"
        echo -e "9) env + export (Unstable) (117 Cases)"
        # echo -e "g) Word Splitting (120 Cases)"
        # echo -e "h) Operators & Punctuation (80 Cases)"
        # echo -e "i) Parentheses & Priority (50 Cases)"
        # echo -e "j) Combined Tokenization (268 Cases)"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
        echo
        read -n 1 -rp "Select an option: " choice

        case $choice in
            a) execute_test "all"           "false"             ;;
            b) execute_test "all"           "true"              ;;
            c) run_all_tokenization_cases                       ;;
            d) execute_test "expansion.xlsx"                    ;;
            1) execute_test "../program/echo_expansion.xlsx"    ;;
            2) execute_test "../program/cd.xlsx"                ;;
            3) execute_test "../program/execution.xlsx"         ;;
            4) execute_test "../program/redirections.xlsx"      ;;
            5) execute_test "../program/exit.xlsx"              ;;
            6) execute_test "../program/unset.xlsx"             ;;
            7) execute_test "../program/basic_cases.xlsx"       ;;
            8) execute_test "../program/complex_cases.xlsx"     ;;
            9) execute_test "../program/export.xlsx"            ;;
            g) execute_test "word_splitting.xlsx"               ;;
            h) execute_test "operators_punctuation.xlsx"        ;;
            i) execute_test "parentheses_priority.xlsx"         ;;
            j) execute_test "combined_tokenization.xlsx"        ;;
            f) break ;;
            *) echo "Invalid option."; sleep 1 ;;
        esac
    done
}
