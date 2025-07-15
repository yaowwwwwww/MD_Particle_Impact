#!/bin/bash

cd "$(dirname "$0")"

echo "Running LAMMPS bicrystal simulation..."
./lmp -in in.crystallize

if [ -f dump.gb ]; then
    echo "Opening result in OVITO..."
    ovito dump.gb &
else
    echo "Error: dump.gb not found. Simulation may have failed."
fi
