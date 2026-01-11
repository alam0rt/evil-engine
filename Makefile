# Evil Engine - Makefile for running demo scenes
#
# Usage:
#   make              - Build the GDExtension library
#   make run          - Run the default scene (parallax_viewer)
#   make parallax     - Run the parallax viewer
#   make level        - Run the level viewer
#   make scene        - Run the level scene (interactive)
#   make clean        - Clean build artifacts

.PHONY: all build run parallax level scene clean help

# Default BLB path for testing
BLB_PATH ?= /home/sam/projects/btm/disks/blb/GAME.BLB

# Godot executable
GODOT ?= godot

# Build directory
BUILD_DIR = build

all: build

# Build the C library and tools with meson/ninja
build:
	@if [ ! -f $(BUILD_DIR)/build.ninja ]; then \
		meson setup $(BUILD_DIR); \
	fi
	ninja -C $(BUILD_DIR)

# Run the default demo scene (parallax viewer)
run: parallax

# Run parallax viewer - PSX-accurate parallax scrolling demo
parallax: build
	$(GODOT) --path . demo/parallax_viewer.tscn

# Run level viewer - simple level rendering
level: build
	$(GODOT) --path . demo/level_viewer.tscn

# Run level scene - interactive viewer with camera controls
scene: build
	$(GODOT) --path . demo/level_scene.tscn

# Run with editor (for debugging)
editor:
	$(GODOT) --path . --editor

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f /tmp/evil_*.ppm /tmp/evil_layers/*

# Help
help:
	@echo "Evil Engine - Demo Scenes"
	@echo ""
	@echo "Targets:"
	@echo "  make              Build the GDExtension library"
	@echo "  make run          Run default scene (parallax_viewer)"
	@echo "  make parallax     Run parallax viewer (PSX-accurate)"
	@echo "  make level        Run level viewer (simple)"
	@echo "  make scene        Run level scene (interactive)"
	@echo "  make editor       Open in Godot editor"
	@echo "  make clean        Clean build artifacts"
	@echo ""
	@echo "Environment:"
	@echo "  GODOT=<path>      Path to Godot executable (default: godot)"
	@echo "  BLB_PATH=<path>   Path to GAME.BLB file"
