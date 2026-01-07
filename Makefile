.PHONY: setup setup-tools setup-python setup-uv setup-node setup-deps setup-hooks \
        build-css watch-css run export-requirements help

# Read versions from version files (single source of truth)
PYTHON_VERSION := $(shell cat .python-version 2>/dev/null | head -1 || echo "3.11")
NODE_VERSION := $(shell cat .node-version 2>/dev/null | head -1 || echo "20")

help:
	@echo "Available targets:"
	@echo "  make setup       - Full development environment setup"
	@echo "  make setup-tools - Install uv and Python via mise/asdf"
	@echo "  make setup-node  - Install Node.js dependencies"
	@echo "  make setup-deps  - Install Python dependencies"
	@echo "  make setup-hooks - Install pre-commit hooks"
	@echo ""
	@echo "  make run         - Start the development server"
	@echo "  make build-css   - Build Tailwind CSS for production"
	@echo "  make watch-css   - Watch and rebuild CSS on changes"
	@echo "  make export-requirements - Regenerate requirements.txt"

setup: setup-tools setup-deps setup-node setup-hooks
	@echo ""
	@echo "✅ Setup complete! Run 'make run' to start the server."

setup-tools: setup-uv setup-python

setup-uv:
	@echo "🔧 Checking for uv..."
	@if command -v uv >/dev/null 2>&1; then \
		echo "  ✓ uv is installed: $$(uv --version)"; \
	elif command -v mise >/dev/null 2>&1; then \
		echo "  → Installing uv via mise..."; \
		mise install uv; \
		mise use uv@latest; \
	elif command -v asdf >/dev/null 2>&1; then \
		echo "  → Installing uv via asdf..."; \
		asdf plugin add uv 2>/dev/null || true; \
		asdf install uv latest; \
		asdf local uv latest; \
	else \
		echo "  → Installing uv via standalone installer..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
		echo "  ⚠️  You may need to restart your shell or run: source ~/.cargo/env"; \
	fi

setup-python:
	@echo "🐍 Checking for Python $(PYTHON_VERSION)..."
	@if command -v mise >/dev/null 2>&1; then \
		echo "  → Using mise to install Python $(PYTHON_VERSION)..."; \
		mise settings add idiomatic_version_file_enable_tools python 2>/dev/null || true; \
		mise install python@$(PYTHON_VERSION); \
	elif command -v asdf >/dev/null 2>&1; then \
		echo "  → Using asdf to install Python $(PYTHON_VERSION)..."; \
		asdf plugin add python 2>/dev/null || true; \
		asdf install python $(PYTHON_VERSION); \
		asdf local python $(PYTHON_VERSION); \
	elif command -v pyenv >/dev/null 2>&1; then \
		echo "  → Using pyenv to install Python $(PYTHON_VERSION)..."; \
		pyenv install -s $(PYTHON_VERSION); \
		pyenv local $(PYTHON_VERSION); \
	else \
		echo "  ⚠️  No Python version manager found (mise/asdf/pyenv)"; \
		echo "     Please install Python $(PYTHON_VERSION) manually"; \
		if python3 --version 2>/dev/null | grep -q "$(PYTHON_VERSION)"; then \
			echo "  ✓ System Python $(PYTHON_VERSION) found"; \
		fi; \
	fi

setup-deps:
	@echo "📦 Installing Python dependencies..."
	@if command -v uv >/dev/null 2>&1; then \
		uv sync --extra dev; \
	elif command -v mise >/dev/null 2>&1 && mise which uv >/dev/null 2>&1; then \
		mise exec -- uv sync --extra dev; \
	else \
		echo "  ⚠️  uv not found. Run 'make setup-uv' first."; \
		exit 1; \
	fi

setup-node:
	@echo "🟢 Checking for Node.js $(NODE_VERSION)..."
	@if command -v mise >/dev/null 2>&1; then \
		mise settings add idiomatic_version_file_enable_tools node 2>/dev/null || true; \
		mise install node@$(NODE_VERSION); \
		echo "📦 Installing Node.js dependencies..."; \
		mise exec -- npm install; \
	elif command -v asdf >/dev/null 2>&1; then \
		asdf plugin add nodejs 2>/dev/null || true; \
		asdf install nodejs $(NODE_VERSION); \
		asdf local nodejs $(NODE_VERSION); \
		echo "📦 Installing Node.js dependencies..."; \
		npm install; \
	elif command -v fnm >/dev/null 2>&1; then \
		fnm install $(NODE_VERSION); \
		fnm use $(NODE_VERSION); \
		echo "📦 Installing Node.js dependencies..."; \
		npm install; \
	elif command -v nvm >/dev/null 2>&1; then \
		. "$$NVM_DIR/nvm.sh" && nvm install $(NODE_VERSION) && nvm use $(NODE_VERSION); \
		echo "📦 Installing Node.js dependencies..."; \
		npm install; \
	elif command -v npm >/dev/null 2>&1; then \
		echo "  ✓ Node.js found: $$(node --version)"; \
		echo "📦 Installing Node.js dependencies..."; \
		npm install; \
	else \
		echo "  ⚠️  No Node.js version manager found (mise/asdf/fnm/nvm)"; \
		echo "     Please install Node.js $(NODE_VERSION) manually"; \
		echo "     CSS is pre-built, so this is optional for running the app."; \
	fi

setup-hooks:
	@echo "🪝 Installing pre-commit hooks..."
	@if command -v uv >/dev/null 2>&1; then \
		uv run pre-commit install; \
	elif command -v mise >/dev/null 2>&1; then \
		mise exec -- uv run pre-commit install; \
	else \
		echo "  ⚠️  uv not found. Run 'make setup-uv' first."; \
		exit 1; \
	fi
	@echo "  ✓ Pre-commit hooks installed"

# Development commands
run:
	@uv run python main.py

build-css:
	@npm run build-css

watch-css:
	@npm run watch-css

export-requirements:
	@echo "📄 Regenerating requirements.txt..."
	@uv export --extra rpi --no-hashes -o requirements.txt
	@echo "  ✓ requirements.txt updated"
