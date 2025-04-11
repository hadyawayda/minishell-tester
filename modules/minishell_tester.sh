#!/usr/bin/env bash

minishell_tester_menu() {
    while true; do
        clear
        echo -e "${BLUE}----- Minishell Tester -----${GREEN}"
        echo -e "a) ${CYAN}Run All Cases (Interactive, 711 Cases)${GREEN}"
        echo -e "b) ${CYAN}Run All Cases (No Pause, 711 Cases)${GREEN}"
        echo -e "1) Echo (108 Cases)"
        echo -e "2) CD (71 Cases)"
        echo -e "3) Environment Variables (156 Cases)"
        echo -e "4) Execution (98 Cases)"
        echo -e "5) Exit Status (51 Cases)"
        echo -e "6) Expansion (10 Cases)"
        echo -e "7) PWD (11 Cases)"
        echo -e "8) Redirections (141 Cases)"
        echo -e "9) Complex Cases (1 Case)"
        echo -e "0) Basic Cases (57 Cases)${NC}"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}"
        echo -e
    	read -n 1 -rp "Select an option: " choice
        
        case $choice in
            a) execute_test "program" "all" "false" ;;
            b) execute_test "program" "all" "true"  ;;
            1) execute_test "program" "echo.xlsx"          ;;
            2) execute_test "program" "cd.xlsx"            ;;
            3) execute_test "program" "env_export_unset.xlsx" ;;
            4) execute_test "program" "execution.xlsx"     ;;
            5) execute_test "program" "exit.xlsx"          ;;
            6) execute_test "program" "expansion.xlsx"     ;;
            7) execute_test "program" "pwd.xlsx"           ;;
            8) execute_test "program" "redirections.xlsx"  ;;
            9) execute_test "program" "complex_cases.xlsx" ;;
            0) execute_test "program" "basic_cases.xlsx"   ;;
            f) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}
