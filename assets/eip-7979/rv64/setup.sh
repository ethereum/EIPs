# Non-root RISC-V toolchain: cross gcc + qemu-user extracted from
# Ubuntu 22.04 debs into /tmp/rv.  Needs only network and /tmp.
set -e
mkdir -p /tmp/debs /tmp/rv
cd /tmp/debs
apt-get download qemu-user liburing2 binutils-riscv64-linux-gnu \
    gcc-11-riscv64-linux-gnu cpp-11-riscv64-linux-gnu \
    libgcc-11-dev-riscv64-cross libgcc-s1-riscv64-cross
for d in *.deb; do dpkg -x "$d" /tmp/rv; done
cat > /tmp/rvenv.sh <<'EOF'
export LD_LIBRARY_PATH=/tmp/rv/usr/lib/x86_64-linux-gnu
GCC="/tmp/rv/usr/bin/riscv64-linux-gnu-gcc-11 -B /tmp/rv/usr/lib/gcc-cross/riscv64-linux-gnu/11/ -B /tmp/rv/usr/riscv64-linux-gnu/bin/ -O2 -static -nostdlib -nostartfiles -ffreestanding"
QEMU=/tmp/rv/usr/bin/qemu-riscv64
EOF
echo "done: . /tmp/rvenv.sh, then python3 harness.py"
