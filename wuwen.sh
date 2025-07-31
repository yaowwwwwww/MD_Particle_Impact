#!/bin/bash

cd "$(dirname "$0")"

export OMP_NUM_THREADS=80
echo "Running LAMMPS bicrystal simulation..."
# --- 关键修改：在这里指定 LAMMPS 可执行文件的完整路径 ---
/home/wuwen/lammps/build/lmp -in in.impact

if [ -f traj.lammpstrj ]; then
    echo "Opening result in OVITO..."
    ovito traj.lammpstrj &
else
    echo "Error: results not found."
fi
