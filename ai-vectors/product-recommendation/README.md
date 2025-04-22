1. **Install Python 3.12**

   RHEL 9.4 includes Python 3.12 in its package repositories. To install it, run:

   ```bash
   sudo dnf install python3.12
   ```

   Verify the installation:

   ```bash
   python3.12 --version
   ```

2. **Install `pip` for Python 3.12**

   To manage Python packages, install `pip` for Python 3.12:

   ```bash
   sudo dnf install python3.12-pip
   ```

3. **Install `uv` for managing python dependencies
```shell
python3.12 -m pip install uv
```

4. **Add `uv` to the your shell profile
Add this line to your ~/.kshrc, ~/.profile, or ~/.bashrc (depending on your shell setup). In my case, it is ~/.profile
```shell
vi ~/.profile
```
First, find the installation path of `uv`:
```shell
python3.12 -m site --user-base
```

This gave me:
```
/home/shaikhq/.local
```

Add the following line at the end of the file:
```
export PATH="$HOME/.local/bin:$PATH"
```

Saved changes and exited vi editor. 

Apply the changes:
```
. ~/.profile
```

Verify that `uv` is now on the path:
```shell
uv --version
```

uv --version
uv 0.6.15

5. **Create a python virtual environment
```shell
uv venv --python=python3.12
```

6. **Activate the python virtual env:
```shell
source .venv/bin/activate
```

7. **Install packages from `requirements.txt`
uv pip install -r requirements.txt

8. **Configure VS Code to Use the Virtual Environment**

   - Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P` on macOS).
   - Type `Python: Select Interpreter` and select the interpreter located in your `.venv` directory.

9. **Set the Notebook's Python Interpreter in VS Code**

   - Open your Jupyter notebook in VS Code.
   - Click on the kernel name at the top right corner.
   - Select the interpreter from your `.venv`.

10. Rename `.env-sample` to `.env` and populate the required API keys and metadata from your target AI platforms. Fill in the necessary values as shown below:

```env
WATSONX_PROJECT=
WATSONX_APIKEY=
database=
hostname=
port=
protocol=
uid=
pwd=