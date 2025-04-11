#!/usr/bin/env bash

# Run Valgrind Test
run_valgrind_test() {
    local command="$1"
    echo -e "${YELLOW}Running Valgrind for: $command${NC}"
    valgrind --leak-check=full --error-exitcode=42 ./minishell "$command" > /dev/null 2> valgrind.log
    if grep -q 'definitely lost: 0 bytes' valgrind.log; then
        echo -e "${GREEN}No memory leaks detected.${NC}"
    else
        echo -e "${RED}Memory leaks detected!${NC}"
    fi
}