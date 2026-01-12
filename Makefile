# Evil Engine - Makefile for running demo scenes
#
# Usage:
#   make              - Build the GDExtension library
#   make run          - Run the default scene (parallax_viewer)
#   make parallax     - Run the parallax viewer
#   make level        - Run the level viewer
#   make scene        - Run the level scene (interactive)
#   make clean        - Clean build artifacts
#
# Level/Stage Selection:
#   make parallax LEVEL=5 STAGE=2    - Load specific level and stage
#   make parallax LEVEL=23           - Load RUNN (level 23)
#
# Level Index Reference:
#   0=MENU, 1=GLEN, 2=SCIE, 3=CRYS, 4=WEED, 5=HEAD, 6=BOIL, 7=TMPL,
#   8=CAVE, 9=FOOD, 10=CSTL, 11=CLOU, 12=PHRO, 13=WIZZ, 14=BRG1, 15=MOSS,
#   16=SOAR, 17=EGGS, 18=FINN, 19=GLID, 20=KLOG, 21=SNOW, 22=EVIL, 23=RUNN,
#   24=MEGA, 25=SEVN

.PHONY: all build run parallax level scene clean help test

# Default BLB path for testing
BLB_PATH ?= /home/sam/projects/btm/disks/blb/GAME.BLB

# Level and stage selection (optional)
LEVEL ?=
STAGE ?=

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

# Build command-line args for level/stage
LEVEL_ARGS =
ifdef LEVEL
	LEVEL_ARGS += --level $(LEVEL)
endif
ifdef STAGE
	LEVEL_ARGS += --stage $(STAGE)
endif

# Run parallax viewer - PSX-accurate parallax scrolling demo
parallax: build
	$(GODOT) --path . demo/parallax_viewer.tscn -- $(LEVEL_ARGS)

# Run level viewer - simple level rendering
level: build
	$(GODOT) --path . demo/level_viewer.tscn

# Run level scene - interactive viewer with camera controls
scene: build
	$(GODOT) --path . demo/level_scene.tscn

# Run with editor (for debugging)
editor: build
	$(GODOT) --path . --editor

# Run unit tests
test: build
	@echo "Running BLB Importer tests..."
	$(GODOT) --headless --path . --script addons/blb_importer/blb_reader_test.gd

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
	@echo "  make test         Run unit tests"
	@echo "  make clean        Clean build artifacts"
	@echo ""
	@echo "Environment:"
	@echo "  GODOT=<path>      Path to Godot executable (default: godot)"
	@echo "  BLB_PATH=<path>   Path to GAME.BLB file"
