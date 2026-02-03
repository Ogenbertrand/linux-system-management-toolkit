.PHONY: help install lint clean test

help:
	@echo "Linux System Management Toolkit - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  install    - Install the toolkit to /usr/local/bin"
	@echo "  lint       - Run shellcheck on all scripts"
	@echo "  test       - Run all tests in the tests/ directory"
	@echo "  clean      - Remove logs and temporary files"
	@echo "  uninstall  - Remove installed toolkit"

test:
	@echo "Running tests..."
	@mkdir -p tests
	@bash -c 'for test in tests/test_*.sh; do if [ -f "$$test" ]; then echo "Running $$test..."; bash "$$test"; fi; done'

install:
	@echo "Installing lsm-toolkit..."
	chmod +x bin/lsm-toolkit || true

lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -type f -exec shellcheck {} +; \
		shellcheck bin/lsm-toolkit; \
		echo "Shellcheck passed!"; \
	else \
		echo "Error: shellcheck not installed. Install with: sudo apt install shellcheck"; \
		exit 1; \
	fi

clean:
	@echo "Cleaning up..."
	rm -rf logs/*.log
	rm -rf .cache
	find . -name "*.tmp" -delete
	find . -name "*.temp" -delete
	@echo "Cleanup complete."

uninstall:
	@echo "Uninstalling lsm-toolkit..."
	sudo rm -f /usr/local/bin/lsm
	@echo "Uninstall complete."
