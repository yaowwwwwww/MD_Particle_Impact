#!/bin/bash

cd "$(dirname "$0")"

echo "Running LAMMPS simulation with MPI (80 cores)..."
mpirun -np 40 /home/wuwen/lammps/build/lmp -in in.impact

if [ -f traj.lammpstrj ]; then
    echo "Opening result in OVITO..."
    ovito traj.lammpstrj &
else
    echo "Error: results not found."
fi


# kokkos version
# #!/bin/bash
# set -euo pipefail
# cd "$(dirname "$0")"

# # === 80 核：8 MPI × 每进程 10 线程 ===
# export OMP_NUM_THREADS=10
# export OMP_PROC_BIND=spread
# export OMP_PLACES=cores

# LMP=/home/wuwen/lammps/build/lmp # <- 用你编好的 Kokkos 版可执行路径
# IN=in.impact

# echo "Running LAMMPS (Kokkos OpenMP): 8 MPI x ${OMP_NUM_THREADS} threads = 80 cores"
# mpirun -np 8 "$LMP" -sf kk -k on t ${OMP_NUM_THREADS} -in "$IN"

# # 可选：如果你的输入写的是 dump 到 traj.lammpstrj，就自动开 OVITO
# if [ -f traj.lammpstrj ]; then
#   echo "Opening result in OVITO..."
#   ovito traj.lammpstrj &
# fi
