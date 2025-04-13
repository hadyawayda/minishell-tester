#!/usr/bin/env bash
# set -euo pipefail

# ===============================
# Global path definitions
# ===============================
# 1. ROOT_DIR: minishell/
ROOT_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
# 2. TESTER_DIR: minishell/minishell-tester/
TESTER_DIR="$ROOT_DIR/minishell-tester"
# 3. CONFIG_DIR: minishell/minishell-tester/config
CONFIG_DIR="$TESTER_DIR/config"
# 4. MODULES_DIR: minishell/minishell-tester/modules/
MODULES_DIR="$TESTER_DIR/modules"
# 5. TEST_FILES_DIR: minishell/minishell-tester/test_files/
TEST_FILES_DIR="$TESTER_DIR/test_files"
# 6. TESTER_FILES_DIR: minishell/minishell-tester/tester_files/
TESTER_FILES_DIR="$TESTER_DIR/tester_files"
# 7. CONVERTED_FILES_DIR: minishell/minishell-tester/tester_files/converted_files/
CONVERTED_FILES_DIR="$TESTER_FILES_DIR/converted_files"
# 8. EXECUTION_DIR: minishell/minishell-tester/tester_files/execution/
EXECUTION_DIR="$TESTER_FILES_DIR/execution"
# 9. PROGRAM_TEST_DIR: minishell/minishell-tester/test_files/program/
PROGRAM_TEST_DIR="$TEST_FILES_DIR/program"
# 10. TOKENIZATION_TEST_DIR: minishell/minishell-tester/test_files/tokenization/
TOKENIZATION_TEST_DIR="$TEST_FILES_DIR/tokenization"
# 11. FAILED_TESTS_SUMMARY_DIR: minishell/minishell-tester/tester_files/failed_tests_summary/
FAILED_TESTS_SUMMARY_DIR="$TESTER_FILES_DIR/failed_tests_summary"
# 12. FAILED_SUMMARY_FILE: minishell/minishell-tester/tester_files/failed_summary.txt
FAILED_SUMMARY_FILE="$FAILED_TESTS_SUMMARY_DIR/failed_summary.txt"

# Global counters
declare -g PASSED_TESTS=0
declare -g TOTAL_TESTS=0

# Load external scripts
source ./modules/case_tester.sh
source ./modules/csv_parser.sh
source ./modules/minishell_tester.sh
source ./modules/parsing_tester.sh
source ./modules/settings_menu.sh
source ./modules/summary_parser.sh
source ./modules/test_execution.sh
source ./modules/tokenization_tester_script.sh
source ./modules/tokenization_tester.sh
source ./modules/valgrind_tester.sh

# Load Configuration
CONFIG_FILE="./config/tester_config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
	while IFS='=' read -r key value; do
        if [[ "$key" == "PROGRAM_PROMPT" ]]; then
            PROGRAM_PROMPT="$value"
        fi
    done < "$CONFIG_FILE"
	echo "PROGRAM_PROMPT=\"\"" >> "$CONFIG_FILE"
    echo "VALGRIND_ENABLED=\"0\"" >> "$CONFIG_FILE"
    echo "DEBUGGING=\"0\"" >> "$CONFIG_FILE"
    echo "CUMULATIVE_TESTING=\"0\"" >> "$CONFIG_FILE"
    echo "BONUS_TESTING_ENABLED=\"0\"" >> "$CONFIG_FILE"
fi

source "$CONFIG_FILE"

chmod +x $ROOT_DIR/minishell

# Color Codes
RED='\033[0;31m'
DIMMED_GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[38;5;208m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# Uncomment the following line to enable flashy colors
RED='\033[1;31m'
GREEN="\033[1;32m"

clear
echo -e "${CYAN}Welcome to the Minishell Tester!"
echo -e "${GREEN}This script will help you test your Minishell implementation."
echo -e "Please ensure you have the necessary test files in the correct format (refer to the README file for details)."

if [[ -n "${PROGRAM_PROMPT}" ]]; then
    echo -e "Using pre-configured program prompt name: \\n\\n${CYAN}${PROGRAM_PROMPT}"
	echo -e "\\n${GREEN}To change this, run the settings menu."
    echo -e "\\n${CYAN}Press any key to continue..."
    read -n 1 -s
else
    echo -e "${GREEN}Enter the program prompt name (e.g. 'Minishell>'): \\n"
    echo -ne "${CYAN}$> "
    read -r PROGRAM_PROMPT
    update_config_key "PROGRAM_PROMPT" "$PROGRAM_PROMPT" "$CONFIG_FILE"
fi

# Main Menu
while true; do
    clear
    echo -e "${BLUE}----- Minishell Tester -----"
    echo -e "${GREEN}1) Minishell Tester"
    echo -e "2) Tokenization Tester"
    echo -e "3) Parsing & Tree Tester (Upcoming Feature)"
    echo -e "4) Settings (Upcoming Feature)"
    echo -e "${ORANGE}f) Exit${GREEN}"
    echo -e "${GREEN}"
    read -n 1 -rp "Select an option: " choice
    case $choice in
        1) minishell_tester_menu ;;
        2) tokenization_tester_menu ;;
        3) parsing_tester_menu ;;
        4) settings_menu;;
        f) clear ; exit 0;;
        *) echo -e "${RED}Invalid option.${NC}";;
    esac
done
