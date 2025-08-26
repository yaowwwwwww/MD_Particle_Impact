#!/bin/bash
#SBATCH --job-name=coldspray_test
#SBATCH --array=1-8
#SBATCH --gpus=nvidia_h100_80gb_hbm3_1g.10gb:1   # 用 1/8 H100 ≈ 10GB 显存
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=01:00:00
#SBATCH --output=slurm-%j.out

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
cd $SLURM_SUBMIT_DIR

module load StdEnv/2023 intel/2023.2.1 openmpi/4.1.5
module load cuda/12.2   # 按集群提供的版本调整

# 冲击速度 = 100 到 800 m/s
VEL_MS=$(( -10 * SLURM_ARRAY_TASK_ID ))


RUNDIR="run_${VEL_MS}ms"
mkdir -p "$RUNDIR"
cd "$RUNDIR"

ln -sf ../in.impact .
ln -sf ../impact_AlCu.lmp .

$HOME/comp/yao/lammps/build/lmp \
  -k on g 1 -sf kk -pk kokkos cuda/aware on \
  -in in.impact \
  -var impactvelocity "$VEL_MS" \
  -log log.lammps

# # 运行 LAMMPS（开启 Kokkos CUDA 后端）
# $HOME/comp/yao/lammps/build/lmp -k on g 1 -sf kk -pk kokkos cuda/aware on -in in.impact
# data collection
# cd /home/wuwen123/comp/yao/MD_Particle_Impact
# tar -czvf all_results.tar.gz */*.lammpstrj
#download results
#scp wwuwen123@fir.alliancecan.ca:/home/wuwen123/comp/yao/MD_Particle_Impact/all_results.tar.gz .
