#!/bin/bash

# Check that prerequisites are installed before running script
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is not installed. Exiting..."
  exit 1
fi

if ! command -v python >/dev/null 2>&1; then
  echo "Error: python is not installed. Exiting..."
  exit 1
fi

# Download the SIFT1M dataset
echo "Downloading SIFT1M dataset..."
curl -O "ftp://ftp.irisa.fr/local/texmex/corpus/sift.tar.gz"

# Check if the download was successful
if [ -f "sift.tar.gz" ]; then
    echo "Download successful. Extracting..."
    tar -xzf sift.tar.gz
else
    echo "Error: download failed. Exiting..."
    exit 1
fi

# Check if files exist and are readable
if [ -f "sift/sift_base.fvecs" ] && [ -r "sift/sift_base.fvecs" ] &&
   [ -f "sift/sift_groundtruth.ivecs" ] && [ -r "sift/sift_groundtruth.ivecs" ] &&
   [ -f "sift/sift_learn.fvecs" ] && [ -r "sift/sift_learn.fvecs" ] &&
   [ -f "sift/sift_query.fvecs" ] && [ -r "sift/sift_query.fvecs" ]; then
   echo "All required files exist and are readable."
else
   echo "Error: Not all required files exist or are readable. Exiting..."
   exit 1
fi

# Creating python virtual environment with dependencies
echo "Creating python virtual environment with dependencies..."
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Format vectors into CSV
echo "Formatting vectors into CSV..."
if [ -f "prep_binary.py" ]; then
    python prep_binary.py
else
  echo "Error: missing file prep_binary.py. Exiting..."
  exit 1
fi
