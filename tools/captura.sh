#!/bin/bash
# Uso: tools/captura.sh <setup.gd|-> <saida.png> [frames] [largura altura]   (ABA=mercado tools/captura.sh tools/setup_jogo.gd /tmp/x.png)
cd "$(dirname "$0")/.."
G=${GODOT:-/home/claude/godot-bin/Godot_v4.4.1-stable_linux.x86_64}
timeout 120 xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --resolution 1280x720 tools/captura.tscn -- "$@" 2>&1 | grep -vE "ALSA|audio|dummy|^$|Godot Engine|initialize|init_output" | head -40
