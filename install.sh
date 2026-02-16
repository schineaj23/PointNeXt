#!/usr/bin/env bash
# command to install this enviroment: source init.sh

# install miniconda3 if not installed yet.
#wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
#bash Miniconda3-latest-Linux-x86_64.sh
#source ~/.bashrc


# download openpoints
# git submodule add git@github.com:guochengqian/openpoints.git
git submodule update --init --recursive
git submodule update --remote --merge 

# 1. Clean up
conda deactivate
conda env remove --name openpoints
conda clean --all -y
pip cache purge

# 2. Create Env
conda create -n openpoints -y python=3.12 numpy numba
conda activate openpoints

# 3. Install PyTorch + Toolkit + Compiler (ALL VER 12.6)
# We use 12.6 because it is the most stable release currently available.
conda install pytorch torchvision torchaudio pytorch-cuda=11.5 -c pytorch-nightly -c nvidia
# ^^^ instead of this just run pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu130 --upgrade
# afterwards and force the upgrade. else do some conda-forge fuckery i don't want to get into

# 4. CRITICAL: Override System CUDA
# This forces the setup.py scripts to use the Conda compiler (12.6), not your system compiler (13.0)
# export CUDA_HOME=$CONDA_PREFIX
# export PATH=$CONDA_PREFIX/bin:$PATH

# Verify we are seeing the Conda compiler
which nvcc
# Output MUST be: .../envs/openpoints/bin/nvcc

# 5. Clean & Build Dependencies
# (Make sure you removed 'torch' and 'torch-scatter' from requirements.txt first!)
pip --no-cache-dir install -r requirements.txt

# 6. Install torch-scatter from source (to match local 12.6)
# pip install --verbose --no-build-isolation git+https://github.com/rusty1s/pytorch_scatter.git

# 7. Compile OpenPoints Extensions
clean_build() { rm -rf build dist *.egg-info; }

cd openpoints/cpp/pointnet2_batch
clean_build
python setup.py install
cd ../

cd subsampling
clean_build
python setup.py build_ext --inplace
cd ..

cd pointops/
clean_build
python setup.py install
cd ..

# Blow are functions that optional. Necessary only if interested in reconstruction tasks such as completion
cd chamfer_dist
python setup.py install --user # actually run pip3 install -e . --no-build-isolation
cd ../emd
python setup.py install --user # actually run pip3 install -e . --no-build-isolation
cd ../../../