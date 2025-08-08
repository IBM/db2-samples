### Semantic Search for Product Recommendation Using Db2 Vector AI

This repository contains code and data for implementing a **semantic product recommendation** demo using **IBM Db2's Vector AI** features, planned for release in **Db2 Version 12 Mod Pack 2 (June 2025)**.

---

## 🛍️ Use Case Overview

This demo simulates a scenario at a shoe store where a customer walks in with a reference shoe they found online and wants to find a similar shoe available in the local store. We use **semantic search** over shoe descriptions stored in Db2 to recommend similar products.

---

## ⚙️ Workflow Summary

- A Db2 table is created to store shoe records, which include descriptive attributes (e.g., color, material, type) and metadata (e.g., SKU, store location).
- These records are populated from a **synthetically generated dataset**. You can find the data generation steps in `generate_dataset.ipynb`.
- The full product recommendation logic is implemented in **`similar_shoes_search.ipynb`**, which is self-contained and ready to run.
- It uses **pre-generated vector embeddings** (provided in `shoes-vectors.csv`) to power similarity search, so you can run the demo **without needing API access to external services**.
- If you wish to regenerate the embeddings, Watsonx.ai can be used via the Python SDK.

---

## 🐍 Environment Setup (RHEL 9.4 + Python 3.12)

Follow these steps to set up your environment and run the demo:

### 1. Install Python 3.12

RHEL 9.4 includes Python 3.12 in its package repositories.

```bash
sudo dnf install python3.12
python3.12 --version
```

### 2. Install `pip` for Python 3.12

```bash
sudo dnf install python3.12-pip
```

### 3. Install `uv` (a modern Python package manager)

```bash
python3.12 -m pip install uv
```

### 4. Add `uv` to Your Shell Profile

Determine the user base path:

```bash
python3.12 -m site --user-base
```

This should return something like:

```bash
/home/<your-username>/.local
```

Edit your shell profile:

```bash
vi ~/.profile  # or ~/.bashrc, ~/.kshrc depending on your shell
```

Add the following line:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Apply the changes:

```bash
. ~/.profile
uv --version
# Should output: uv 0.6.15 (or newer)
```

### 5. Create a Python Virtual Environment

```bash
uv venv --python=python3.12
```

### 6. Activate the Virtual Environment

```bash
source .venv/bin/activate
```

### 7. Install Required Packages

```bash
uv pip install -r requirements.txt
```

---

## 🧠 IDE Setup (VS Code)

### 8. Configure VS Code to Use the Virtual Environment

- Open Command Palette: `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
- Search: `Python: Select Interpreter`
- Select: The interpreter inside `.venv`

### 9. Set Notebook Kernel to Virtual Environment

- Open `similar_shoes_search.ipynb`
- Click the kernel name (top-right)
- Choose the `.venv` Python interpreter

---

## 🔐 API Key Configuration

### 10. Rename `.env-sample` to `.env` and Fill in Required Fields

```env
WATSONX_PROJECT=
WATSONX_APIKEY=

database=
hostname=
port=
protocol=
uid=
pwd=
```

> ⚠️ Using Watsonx.ai APIs is optional. Pre-generated embeddings using watsonx.ai API are already provided in `shoes-vectors.csv`.

---

## ✅ Ready to Run

To run the full demo:

1. Activate your environment
2. Launch the `shoes_search.ipynb` notebook
3. Run all cells to walk through the entire workflow