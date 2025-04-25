#!/usr/bin/env bash

tokenization_tester_menu() {
    TEST_TYPE="tokenization"

    while true; do
        clear
        echo -e "${BLUE}----- Tokenization Tester -----${NC}"
        echo -e "${GREEN}a) ${CYAN}Run All Cases (Interactive, 616+ Cases)"
        echo -e "${GREEN}b) ${CYAN}Run All Cases (No Pause, 616+ Cases)"
        echo -e "${GREEN}c) ${CYAN}Run All Cases (Old Version)"
        echo -e "${GREEN}d) Quotations Basic (35 Cases)"
        echo -e "${GREEN}e) Quotations Advanced (400 Cases)"
        echo -e "${GREEN}1) Echo + Expansion (118 Cases)"
        echo -e "${GREEN}2) CD (56 Cases)"
        echo -e "${GREEN}3) Execution (52 Cases)"
        echo -e "${GREEN}4) Redirections (111 Cases)"
        echo -e "${GREEN}5) Exit Status (51 Cases)"
        echo -e "${GREEN}6) unset (52 Cases)"
        echo -e "${GREEN}7) Basic Cases + PWD (59 Cases)"
        echo -e "${GREEN}8) Complex Cases (10 Cases)"
        echo -e "${GREEN}9) env + export (Unstable) (117 Cases)"
        # echo -e "${GREEN}g) Word Splitting (120 Cases)"
        # echo -e "${GREEN}h) Operators & Punctuation (80 Cases)"
        # echo -e "${GREEN}i) Parentheses & Priority (50 Cases)"
        # echo -e "${GREEN}j) Combined Tokenization (268 Cases)"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
        echo
        read -n 1 -rp "Select an option: " choice

        case $choice in
            a) execute_test "all"           "false"     ;;
            b) execute_test "all"           "true"      ;;
            c) run_all_tokenization_cases               ;;
            d) execute_test "quotations.xlsx"           ;;
            e) execute_test "quotations_advanced.xlsx"  ;;
            1) execute_test "echo_expansion.xlsx"       ;;
            2) execute_test "cd.xlsx"                   ;;
            3) execute_test "execution.xlsx"            ;;
            4) execute_test "redirections.xlsx"         ;;
            5) execute_test "exit.xlsx"                 ;;
            6) execute_test "unset.xlsx"                ;;
            7) execute_test "basic_cases.xlsx"          ;;
            8) execute_test "complex_cases.xlsx"        ;;
            9) execute_test "export.xlsx"               ;;
            g) execute_test "word_splitting.xlsx"       ;;
            h) execute_test "operators_punctuation.xlsx" ;;
            i) execute_test "parentheses_priority.xlsx"  ;;
            j) execute_test "combined_tokenization.xlsx" ;;
            f) break ;;
            *) echo "Invalid option."; sleep 1 ;;
        esac
    done
}
