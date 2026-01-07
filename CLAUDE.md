# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Quick Start
- `make setup` - Full environment setup (Python, Node.js, dependencies, pre-commit hooks)
- `make run` - Start the FastAPI server on port 8080

### Other Commands
- `make build-css` - Build and minify Tailwind CSS for production
- `make watch-css` - Watch mode for CSS development
- `make export-requirements` - Regenerate `requirements.txt` from `pyproject.toml`

The Makefile auto-detects version managers (mise, asdf, pyenv, nvm, fnm) for Python and Node.js installation.

## Architecture Overview

Dune Weaver is a web-controlled kinetic sand table system with both hardware and software components:

### Core Application Structure
- **FastAPI backend** (`main.py`) - Main web server with REST APIs and WebSocket support
- **Modular design** with organized modules:
  - `modules/connection/` - Serial and WebSocket connection management for hardware
  - `modules/core/` - Core business logic (patterns, playlists, state management, caching)
  - `modules/led/` - WLED integration for lighting effects  
  - `modules/mqtt/` - MQTT integration capabilities
  - `modules/update/` - Software update management

### Coordinate System
The sand table uses **polar coordinates (θ, ρ)** instead of traditional Cartesian:
- **Theta (θ)**: Angular position in degrees (0-360°)
- **Rho (ρ)**: Radial distance from center (0.0 at center, 1.0 at perimeter)

### Pattern System
- **Pattern files**: `.thr` files in `patterns/` directory containing theta-rho coordinate pairs
- **Pattern format**: Each line contains `theta rho` values separated by space, comments start with `#`
- **Cached previews**: WebP images generated in `patterns/cached_images/` for UI display
- **Custom patterns**: User uploads stored in `patterns/custom_patterns/`

### Hardware Communication
- Supports both **Serial** and **WebSocket** connections to hardware controllers
- **ESP32** or **Arduino** boards control stepper motors
- **Homing system**: Crash-homing method without limit switches
- **Hardware coupling**: Angular and radial axes are mechanically coupled, requiring software compensation

### State Management
- Global state managed in `modules/core/state.py`
- Persistent state saved to `state.json`
- Real-time status updates via WebSocket (`/ws/status`)

### Key Features
- **Playlist system**: Sequential pattern execution with timing control
- **WLED integration**: Synchronized lighting effects during pattern execution
- **Image caching**: Automatic preview generation for all patterns
- **Pattern execution control**: Play, pause, resume, stop, skip functionality
- **MQTT support**: External system integration
- **Software updates**: Git-based update system

## Important Implementation Notes

### Cursor Rules Integration
The project follows FastAPI best practices from `.cursorrules`:
- Use functional programming patterns where possible
- Implement proper error handling with early returns
- Use Pydantic models for request/response validation
- Prefer async operations for I/O-bound tasks
- Follow proper dependency injection patterns

### Hardware Constraints
- Angular axis movement affects radial position due to mechanical coupling
- Software compensates for this coupling automatically
- No physical limit switches - relies on crash-homing for position reference

### Threading and Concurrency
- Uses asyncio for concurrent operations
- Pattern execution runs in background tasks
- Thread-safe connection management with locks
- WebSocket connections for real-time status updates
- **Process Pool** (`modules/core/process_pool.py`): CPU-intensive tasks (preview generation, file parsing) run in separate processes via `ProcessPoolExecutor` to avoid GIL contention with the motion control thread
- Motion thread runs on CPU 0; worker processes pinned to CPUs 1-N for isolation

## Testing and Development

### Running the Application
```bash
make setup    # One-time setup (installs Python, Node.js, dependencies)
make run      # Start the server
```

Or manually:
1. `uv sync` (or `uv sync --extra rpi` on Raspberry Pi)
2. `npm install`
3. `python main.py`

### Dependency Management
- `pyproject.toml` is the source of truth for dependencies
- `requirements.txt` is auto-generated: `uv export --extra rpi --no-hashes -o requirements.txt`
- RPi-specific packages (GPIO, NeoPixel) are in `[project.optional-dependencies] rpi`

### File Structure Conventions
- Pattern files in `patterns/` (can have subdirectories)
- Static assets in `static/` (CSS, JS, images)
- HTML templates in `templates/`
- Configuration files in root directory
- Firmware configurations in `firmware/` subdirectories for different hardware versions