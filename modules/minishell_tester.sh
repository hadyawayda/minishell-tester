#!/usr/bin/env bash

minishell_tester_menu() {
    while true; do
        clear
        echo -e "${BLUE}----- Minishell Tester -----${GREEN}"
        echo -e "a) ${CYAN}Run All Cases (Interactive, 616+ Cases)${GREEN}"
        echo -e "b) ${CYAN}Run All Cases (No Pause, 616+ Cases)${GREEN}"
        echo -e "1) Echo + Expansion (118 Cases)"
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
            a) execute_test "program" "all" "false" ;;
            b) execute_test "program" "all" "true"  ;;
            1) execute_test "program" "echo.xlsx"          ;;
            2) execute_test "program" "cd.xlsx"            ;;
            3) execute_test "program" "execution.xlsx"     ;;
            4) execute_test "program" "redirections.xlsx"  ;;
            5) execute_test "program" "exit.xlsx"          ;;
            6) execute_test "program" "unset.xlsx" ;;
            7) execute_test "program" "basic_cases.xlsx"   ;;
            8) execute_test "program" "complex_cases.xlsx" ;;
            9) execute_test "program" "export.xlsx" ;;
            f) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}
