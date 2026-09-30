#!/usr/bin/env bash
# Re-create the sandbox tool set (nothing outside the repo survives a restart):
#   pyslang (elaboration checks), Verilator (PyPI wheel, smoke simulation), uvm-core 2020.3.1
set -e
TOOLS="${TOOLS:-/home/user/tools}"
mkdir -p "$TOOLS/bin"
python3 -c "import pyslang" 2>/dev/null || pip install -q --break-system-packages pyslang
python3 -c "import verilator" 2>/dev/null || pip install -q --break-system-packages verilator
VBIN="$(python3 -c 'import verilator, os; print(os.path.join(os.path.dirname(verilator.__file__), "bin", "verilator"))')"
ln -sf "$VBIN" "$TOOLS/bin/verilator"
if [ ! -d "$TOOLS/uvm-core" ]; then
  git clone -q --depth 1 --branch 2020.3.1 https://github.com/accellera-official/uvm-core.git "$TOOLS/uvm-core" \
    || git clone -q --depth 1 https://github.com/accellera-official/uvm-core.git "$TOOLS/uvm-core"
fi
grep -q "tools/bin" ~/.bashrc 2>/dev/null || echo "export PATH=$TOOLS/bin:\$PATH" >> ~/.bashrc
echo "tools ready: $(python3 -c 'import pyslang; print("pyslang", pyslang.__version__)') | $("$TOOLS/bin/verilator" --version) | uvm-core: $TOOLS/uvm-core"
