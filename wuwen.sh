#!/bin/bash
#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# ===== parallel agri=====
NP="${NP:-40}"                          # MPI ranks，默认40
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"   # 每rank线程数，默认1（CPU跑就设>1）

# ===== atomsk  =====
ATOMSK_BIN="/home/wuwen/Downloads/atomsk_b0.13.1_Linux-amd64/atomsk"

 

echo "== 1) Atomsk model ：Al substrate + Cu sphere =="

# ====== parameters（Å）======
a_Al=4.05        # fcc Al
a_Cu=3.615       # fcc Cu
NX=40; NY=40; NZ_SUB=20          # 衬底尺寸（晶胞数）
R=20.0; GAP=10.0; LZ=150.0       # 球半径/间隙/盒高
NCU=14                            # Cu 方块边长的晶胞数（需 > 2R/a_Cu）

# 派生量
LX=$(awk -v a="$a_Al" -v n="$NX" 'BEGIN{printf "%.3f",a*n}')
LY=$(awk -v a="$a_Al" -v n="$NY" 'BEGIN{printf "%.3f",a*n}')
ZCUT=$(awk -v a="$a_Al" -v n="$NZ_SUB" 'BEGIN{printf "%.3f",a*n}')
CX=$(awk -v lx="$LX" 'BEGIN{printf "%.3f",0.5*lx}')
CY=$(awk -v ly="$LY" 'BEGIN{printf "%.3f",0.5*ly}')
CZ=$(awk -v z="$ZCUT" -v gap="$GAP" -v r="$R" 'BEGIN{printf "%.3f",z+gap+r}')
HX=$(awk -v a="$a_Cu" -v n="$NCU" 'BEGIN{printf "%.3f",0.5*a*n}')   # Cu 方块中心
HY="$HX"; HZ="$HX"

cat > box.txt <<EOF
conventional
$LX $LY $LZ
90 90 90
EOF

# Al 衬底
"$ATOMSK_BIN" --create fcc "$a_Al" Al orient [100] [010] [001] \
  -duplicate "$NX" "$NY" "$NZ_SUB" \
  -cut above "$ZCUT" z \
  -properties box.txt \
  al_substrate.cfg

# Cu 球（先块→切球→平移到球心→wrap）
"$ATOMSK_BIN" --create fcc "$a_Cu" Cu orient [100] [010] [001] \
  -duplicate "$NCU" "$NCU" "$NCU" \
  -select out sphere "$HX" "$HY" "$HZ" "$R" \
  -rmatom select \
  -properties box.txt \
  -shift "$(awk -v cx="$CX" -v hx="$HX" 'BEGIN{printf "%.3f",cx-hx}')" \
          "$(awk -v cy="$CY" -v hy="$HY" 'BEGIN{printf "%.3f",cy-hy}')" \
          "$(awk -v cz="$CZ" -v hz="$HZ" 'BEGIN{printf "%.3f",cz-hz}')" \
  -wrap \
  cu_sphere.cfg

# export LAMMPS data（ 1=Al, 2=Cu）
"$ATOMSK_BIN" --merge 2 al_substrate.cfg cu_sphere.cfg impact_AlCu.cfg lammps
[[ -f impact_AlCu.lmp ]] || { echo "ERROR: impact_AlCu.lmp  failed."; exit 1; }
echo ">> model established:impact_AlCu.lmp"

# ===== 运行 LAMMPS =====
echo "== 2) Running LAMMPS: ${NP} MPI ranks × ${OMP_NUM_THREADS} OMP threads = $((NP*OMP_NUM_THREADS)) 并行 =="

mpirun -np "$NP" env OMP_NUM_THREADS="$OMP_NUM_THREADS" \
  /home/wuwen/lammps/build/lmp -in in.impact

# ===== 打开可视化结果 =====
# 依次尝试常见轨迹文件名
for f in traj.lammpstrj dump*.lammpstrj *.lammpstrj; do
  if [[ -f "$f" ]]; then
    echo "Opening result in OVITO: $f"
    nohup ovito "$f" >/dev/null 2>&1 &
    exit 0
  fi
done
echo "Error: results not found."


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
