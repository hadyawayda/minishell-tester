#!/usr/bin/env bash

# add option to toggle running all tests within the same instance or exit after each test

# update_config_key KEY VALUE FILE
# Replaces KEY=... line in FILE if it exists, or appends if it doesn't
function update_config_key() {
    local key="$1"
    local value="$2"
    local config_file="$3"
    
    # Use sed with quotes around the replacement value
    if grep -q "^${key}=" "$config_file"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$config_file"
    else
        echo "${key}=\"${value}\"" >> "$config_file"
    fi
}

# Settings Menu
settings_menu() {
    while true; do
        clear
        echo -e "${BLUE}----- Settings -----${NC}"
        echo -e "${GREEN}1) Set Excel file for test cases (Current: ${BLUE}'$EXCEL_FILE'${GREEN})"
        echo -e "2) Toggle Valgrind usage (Current: ${BLUE}'$VALGRIND_ENABLED'${GREEN})"
        echo -e "${GREEN}3) Toggle comparison method (Current: ${BLUE}'$COMPARISON_METHOD'${GREEN})"
        echo -e "${GREEN}4) Toggle bonus testing (Current: ${BLUE}'$BONUS_TESTING_ENABLED'${GREEN})"
        echo -e "${GREEN}5) Set Program Prompt (Current: ${BLUE}'$PROGRAM_PROMPT'${GREEN})"
        echo -e "${GREEN}6) Toggle Debugging Logs (Current: ${BLUE}'$DEBUGGING'${GREEN})"
        echo -e "${ORANGE}f) Return to Main Menu"
        echo -e "${GREEN}"
        read -n 1 -rp "Select an option: " choice
		
        case $choice in
            1)
				echo -ne "${BLUE}\\n\\nEnter path to Excel file: ${GREEN}"
                read -r
                update_config_key "EXCEL_FILE" "$EXCEL_FILE" "$CONFIG_FILE"
                ;;
            2)
                VALGRIND_ENABLED=$((1 - VALGRIND_ENABLED))
                update_config_key "VALGRIND_ENABLED" "$VALGRIND_ENABLED" "$CONFIG_FILE"
                ;;
            3)
                COMPARISON_METHOD=$([[ "$COMPARISON_METHOD" == "csv" ]] && echo "bash" || echo "csv")
                update_config_key "COMPARISON_METHOD" "$COMPARISON_METHOD" "$CONFIG_FILE"
                ;;
            4)
                BONUS_TESTING_ENABLED=$((1 - BONUS_TESTING_ENABLED))
                update_config_key "BONUS_TESTING_ENABLED" "$BONUS_TESTING_ENABLED" "$CONFIG_FILE"
                ;;
            5)
				echo -ne "${BLUE}\\n\\nEnter new Program Prompt (e.g. Minishell>): ${GREEN}"
                read -r PROGRAM_PROMPT
                update_config_key "PROGRAM_PROMPT" "$PROGRAM_PROMPT" "$CONFIG_FILE"
                ;;
            6)
                DEBUGGING=$((1 - DEBUGGING))
                update_config_key "DEBUGGING" "$DEBUGGING" "$CONFIG_FILE"
                ;;
            f) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}
