#!/usr/bin/env bash

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

settings_menu() {
    while true; do
        clear
        echo -e "${BLUE}----- Settings -----${GREEN}"
        echo -e "1) Set Program Prompt (Current: ${BLUE}'$PROGRAM_PROMPT'${GREEN})"
        echo -e "2) Toggle Valgrind usage (Current: ${BLUE}'$VALGRIND_ENABLED'${GREEN})"
        echo -e "3) Toggle Debugging Logs (Current: ${BLUE}'$DEBUGGING'${GREEN})"
        echo -e "4) Toggle cumulative testing inside the same instance - Better testing quality but errors are more likely to occur due to possibly poor memory management (Current: ${BLUE}'$CUMULATIVE_TESTING'${GREEN})"
        echo -e "5) Toggle bonus testing (Current: ${BLUE}'$BONUS_TESTING_ENABLED'${GREEN})"
        echo -e "${ORANGE}f) Return to Main Menu${GREEN}\\n"
        read -n 1 -rp "Select an option: " choice
		
        case $choice in
            1)
				echo -ne "${BLUE}\\n\\nEnter new Program Prompt (e.g. Minishell>): ${GREEN}"
                read -r PROGRAM_PROMPT
                update_config_key "PROGRAM_PROMPT" "$PROGRAM_PROMPT" "$CONFIG_FILE"
                ;;
            2)
                VALGRIND_ENABLED=$((1 - VALGRIND_ENABLED))
                update_config_key "VALGRIND_ENABLED" "$VALGRIND_ENABLED" "$CONFIG_FILE"
                ;;
            3)
                DEBUGGING=$((1 - DEBUGGING))
                update_config_key "DEBUGGING" "$DEBUGGING" "$CONFIG_FILE"
                ;;
            4)
                CUMULATIVE_TESTING=$((1 - CUMULATIVE_TESTING))
                update_config_key "CUMULATIVE_TESTING" "$CUMULATIVE_TESTING" "$CONFIG_FILE"
                ;;
            5)
                BONUS_TESTING_ENABLED=$((1 - BONUS_TESTING_ENABLED))
                update_config_key "BONUS_TESTING_ENABLED" "$BONUS_TESTING_ENABLED" "$CONFIG_FILE"
                ;;
            f) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}
