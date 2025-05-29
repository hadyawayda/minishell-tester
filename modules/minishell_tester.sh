#!/usr/bin/env bash

minishell_tester_menu() {
    TEST_TYPE="program"

    while true; do
        clear
        echo -e "${BLUE}----- Minishell Tester -----${GREEN}"
        echo -e "a) ${CYAN}Run All Cases (Interactive, 616+ Cases)${GREEN}"
        echo -e "b) ${CYAN}Run All Cases (No Pause, 616+ Cases)${GREEN}"
		echo -e "c) Expansion (410 Cases)"
		echo -e "d) Wildcards (70 Cases)"
        echo -e "1) Echo (118 Cases)"
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
            a) execute_test "all" "false" ;;
            b) execute_test "all" "true"  ;;
            c) execute_test "../tokenization/expansion.xlsx"          ;;
            d) execute_test "../tokenization/wildcards.xlsx"          ;;
            1) execute_test "echo.xlsx"          ;;
            2) execute_test "cd.xlsx"            ;;
            3) execute_test "execution.xlsx"     ;;
            4) execute_test "redirections.xlsx"  ;;
            5) execute_test "exit.xlsx"          ;;
            6) execute_test "unset.xlsx" ;;
            7) execute_test "basic_cases.xlsx"   ;;
            8) execute_test "complex_cases.xlsx" ;;
            9) execute_test "export.xlsx" ;;
            f) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}
