#!/usr/bin/env bash
set -e

# ======= 可调参数（单位 Å）=======
# 晶格常数（按你的势函数改）：
a_Al=4.05        # fcc Al
a_Cu=3.615       # fcc Cu

# 衬底横向尺寸：用 Al 的整数晶胞
NX=40            # Lx ≈ NX*a_Al = 162.0 Å
NY=40            # Ly ≈ NY*a_Al = 162.0 Å
NZ_SUB=20        # 衬底厚度 ≈ NZ_SUB*a_Al = 81.0 Å

# Cu 球
R=20.0           # 半径
GAP=10.0         # 球底与衬底面的间隙

# 盒子总高（给点余量便于真空/加速段）
LZ=150.0         # 总高度（Å）

# 为保证 Cu 球“胚料”足够大（>直径）
NCU=14           # ≈ NCU*a_Cu = 50.6 Å 的立方块

# ======= 衍生量 =======
LX=$(awk -v a=$a_Al -v n=$NX 'BEGIN{printf "%.3f",a*n}')
LY=$(awk -v a=$a_Al -v n=$NY 'BEGIN{printf "%.3f",a*n}')
ZCUT=$(awk -v a=$a_Al -v n=$NZ_SUB 'BEGIN{printf "%.3f",a*n}')       # 衬底厚度(=裁切面)
CX=$(awk -v lx=$LX 'BEGIN{printf "%.3f",0.5*lx}')                    # 球心 x
CY=$(awk -v ly=$LY 'BEGIN{printf "%.3f",0.5*ly}')                    # 球心 y
CZ=$(awk -v z=$ZCUT -v gap=$GAP -v r=$R 'BEGIN{printf "%.3f",z+gap+r}')  # 球心 z

echo "Box: ${LX} x ${LY} x ${LZ} Å,  Substrate thickness: ${ZCUT} Å,  Sphere center: (${CX},${CY},${CZ})"

# 写一个通用盒参数文件（给 -properties 用）
cat > box.txt <<EOF
conventional
$LX $LY $LZ
90 90 90
EOF

# ========== 1) 构建 Al 衬底（取向 [100]/[010]/[001]，裁成 slab，并设成目标盒） ==========
atomsk --create fcc $a_Al Al orient [100] [010] [001] \
  -duplicate $NX $NY $NZ_SUB \
  -cut above $ZCUT z \
  -properties box.txt \
  al_substrate.cfg

# ========== 2) 构建 Cu 实心球 ==========
# 先做一个足够大的 Cu 立方块 -> 切出球体 -> 放进同尺寸盒子 -> 平移到指定球心 -> wrap
atomsk --create fcc $a_Cu Cu orient [100] [010] [001] \
  -duplicate $NCU $NCU $NCU \
  -select out sphere 0.5*box 0.5*box 0.5*box $R \
  -rmatom select \
  -properties box.txt \
  -shift $(awk -v a=$a_Cu -v n=$NCU -v cx=$CX 'BEGIN{printf "%.3f",cx-0.5*a*n}') \
          $(awk -v a=$a_Cu -v n=$NCU -v cy=$CY 'BEGIN{printf "%.3f",cy-0.5*a*n}') \
          $(awk -v a=$a_Cu -v n=$NCU -v cz=$CZ 'BEGIN{printf "%.3f",cz-0.5*a*n}') \
  -wrap \
  cu_sphere.cfg

# ========== 3) 合并到同一个盒子并导出 LAMMPS ==========
# 省略方向参数 → 默认把两个系统“聚合到第一个文件的盒子里”，原子坐标不再自动调整
atomsk --merge 2 al_substrate.cfg cu_sphere.cfg impact_AlCu.cfg lammps

echo "Done. Files: impact_AlCu.cfg  and  impact_AlCu.lmp"
