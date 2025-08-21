#!/bin/bash
#SBATCH --job-name=coldspray_test
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --time=00:10:00
#SBATCH --output=slurm-%j.out

# 切换到提交作业时的目录
cd $SLURM_SUBMIT_DIR

# 加载需要的模块（根据sever and build lammps 时的环境）
module load StdEnv/2023 intel/2023.2.1 openmpi/4.1.5

# 运行 LAMMPS（开启 Kokkos CUDA 后端）
$HOME/comp/yao/lammps/build/lmp -k on g 1 -sf kk -pk kokkos cuda/aware on -in in.impact
