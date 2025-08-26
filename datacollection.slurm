#!/bin/bash
#SBATCH --job-name=data_collect
#SBATCH --account=def-dengc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8         # 多给几个 CPU，加速压缩
#SBATCH --time=01:00:00
#SBATCH --output=slurm-%j-datacollect.out

cd /home/wuwen123/comp/yao/MD_Particle_Impact || exit 1

echo "Start collecting results at $(date)"

# 输出文件名
OUTFILE="all_results.tar.gz"

# 检查 pigz 是否可用
if command -v pigz &> /dev/null; then
    echo "Using pigz with ${SLURM_CPUS_PER_TASK} threads for compression"
    tar --use-compress-program="pigz -p ${SLURM_CPUS_PER_TASK}" \
        -cvf "$OUTFILE" */*.lammpstrj
else
    echo "pigz not found, falling back to gzip (single-thread)"
    tar -czvf "$OUTFILE" */*.lammpstrj
fi

echo "Archive created: $OUTFILE"
echo "Finished at $(date)"
