# Implementing Retrieval-Augmented Generation with IBM Db2, watsonx.ai, LangChain

## Introduction

This README presents step-by-step instructions for implementing a Retrieval-Augmented Generation (RAG) use case using IBM Db2, watsonx.ai, and LangChain. The complete is available in the [`rag-basic.ipynb`](rag-basic.ipynb) notebook in the same folder,  In March 2025 Early Access Program (EAP) build , Db2 introduced a native vector data type and vector similarity search functionality. Leveraging these capabilities, I have implemented a complete RAG pipeline with LangChain and Python in a Jupyter Notebook. Customers with access to [this](http://ibm.biz/db2_early_access_program) EAP build can try out these features in a non-production setup.  

## Understanding Retrieval-Augmented Generation

Large Language Models (LLMs) are typically limited to the knowledge present in their training data, which can lead to two main challenges:

1. **Generic Responses**: The model may provide answers that are too broad and not tailored to the user's specific intent.
2. **Hallucinations**: If the answer is not within the training corpus, the model might generate inaccurate or fabricated responses.

Retrieval-Augmented Generation addresses these issues by incorporating external knowledge into the LLM's responses. It retrieves relevant documents from a knowledge base and augments the LLM's prompt with additional context, thereby enhancing accuracy and relevance.

## Db2 Vector Capabilities in the EAP Release

Db2's EAP release introduces vector operations with the following features:

- **Vector Data Type**: `VECTOR(dimensions, coordinate_type)`
  - Supported coordinate types:
    - `INT8`: 8-bit integer values
    - `FLOAT32` or `REAL`: 32-bit floating-point numbers
  - Fixed vector dimensions per column

  The syntax for defining a `VECTOR` column in a Db2 table is as follows:

  ```sql
  VECTOR(dimension, coordinate_type)
  ```

  For example, to define a vector column with 1024 dimensions using 32-bit floating-point numbers, you would specify:

  ```sql
  VECTOR(1024, FLOAT32)
  ```

- **Vector Distance Function**: `VECTOR_DISTANCE(vector1, vector2, metric)`
  - Calculates the distance between two vectors using the specified distance metric.
  - Supported distance metrics include:
    - `COSINE`: Measures the cosine of the angle between two vectors.
    - `EUCLIDEAN`: Computes the straight-line distance between two vectors.
    - `EUCLIDEAN_SQUARED`: Calculates the squared Euclidean distance, avoiding the computational cost of the square root.
    - `DOT`: Computes the negative dot product of two vectors.
    - `HAMMING`: Counts the number of dimensions that differ between two vectors.
    - `MANHATTAN`: Also known as L1 distance, it sums the absolute differences across dimensions.

  The syntax for the `VECTOR_DISTANCE` function is:

  ```sql
  VECTOR_DISTANCE(vector1, vector2, metric)
  ```

  For example, to calculate the cosine distance between two vectors:

  ```sql
  VECTOR_DISTANCE(vector1, vector2, COSINE)
  ```

These enhancements allow Db2 to efficiently store and process high-dimensional data, facilitating advanced functionalities like retrieval-augmented generation (RAG) pipelines.

## Implementing the RAG Pipeline

### 1. Setting Up the Python Environment
I created this tutorial on RHEL 9.4 using Python 3.12. Below are the steps I followed to set up the Python environment on RHEL 9.4.

**Installing Python 3.12**

Open a terminal and execute the following commands:

```bash
sudo dnf install python3.12
```

Verify the installation:

```bash
python3.12 --version
```

**Installing `pip` for Python 3.12**

To manage Python packages, install `pip` for Python 3.12:

```bash
sudo dnf install python3.12-pip
```

**Creating a Virtual Environment**

Navigate to your project directory:

```bash
cd ~/db2ai-demos/rag-basic/
```

Create a virtual environment named `.venv` using Python 3.12:

```bash
python3.12 -m venv .venv
```

Activate the virtual environment:

```bash
source .venv/bin/activate
```

With the virtual environment activated, install the required libraries specified in your `requirements.txt` file:

```bash
pip install -r requirements.txt
```

### 2. Configuring VS Code to Use the Virtual Environment

To ensure that Visual Studio Code (VS Code) utilizes the Python interpreter from your virtual environment:

- Open VS Code.
- Navigate to your project directory: `~/db2ai-demos/rag-basic/`.
- Open the Command Palette by pressing `Ctrl+Shift+P`.
- Type and select `Python: Select Interpreter`.
- Choose the interpreter that points to your `.venv` directory, which should resemble:

  ```
  .venv/bin/python
  ```

For detailed guidance, refer to the VS Code documentation on Python environments.

### 3. Configuring VS Code for Jupyter Notebooks

If your project includes Jupyter Notebooks:

- Open the notebook file in VS Code.
- Click on the kernel name at the top right corner of the notebook interface.
- From the dropdown list, select the interpreter corresponding to your `.venv` environment.

This configuration ensures that the notebook runs using the Python interpreter and libraries from your virtual environment.

### 4. Creating a Knowledge Base

For this demonstration, I used an article I previously published on machine learning in Db2, specifically on building an inference model for linear regression. I will build a knowledge base using this article and instruct the LLM to answer only based on its contents.

### 5. Storing Vectorized Chunks in Db2

The workflow involves:

1. **Chunking the Document**: The article is split into 1024-character chunks with a 200-character overlap.
2. **Generating Embeddings**: Using an embedding model from Watsonx.ai, each chunk is converted into a vector.
3. **Storing in Db2**: Each chunk, its embedding, and metadata are stored in a Db2 table as vectors.

### 6. Querying the Knowledge Base

1. **Vectorizing Questions**: Questions are converted into vectors using the same embedding model.
2. **Similarity Search**: The question vector is compared with stored chunk vectors using vector similarity search.
3. **Augmenting the Prompt**: Retrieved chunks are appended to the LLM query to generate a more accurate response.

## Db2 Implementation Details

### Defining the Vector Table

```sql
CREATE TABLE embeddings (
    id INT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    content CLOB,
    source VARCHAR(255),
    title VARCHAR(255),
    embedding VECTOR(1024, FLOAT32),
    PRIMARY KEY (id)
);
```

### Inserting Vectorized Chunks

```sql
INSERT INTO embeddings(content, source, title, embedding)
VALUES (?, ?, ?, VECTOR('[{embedding_vector_str}]', 1024, FLOAT32));
```

Apologies for the earlier omission. Let's delve into the roles and configurations of the `.env` and `sql.env` files in our project.

## Environment Configuration with `.env` File

The `.env` file is a simple text file used to store environment variables and configuration settings for your project. This approach enhances security and flexibility by separating sensitive information from the source code. In Python projects, the `python-dotenv` library is commonly used to load these variables.

**Sample `.env` File:**

```
WATSONX_PROJECT=your_watsonx_project_id
WATSONX_APIKEY=your_watsonx_api_key
DATABASE=your_db2_database_name
HOSTNAME=your_db2_host
PORT=50000
PROTOCOL=tcpip
UID=your_db2_username
PWD=your_db2_password
```

**Explanation of Variables:**

- `WATSONX_PROJECT`: Your Watsonx.ai project identifier.
- `WATSONX_APIKEY`: API key for authenticating with Watsonx.ai services.
- `DATABASE`: Name of your IBM Db2 database.
- `HOSTNAME`: Hostname or IP address where your Db2 instance is running.
- `PORT`: Port number for connecting to Db2 (default is 50000).
- `PROTOCOL`: Communication protocol to use (typically `tcpip`).
- `UID`: Username for Db2 authentication.
- `PWD`: Password for the Db2 user.

Now, open the notebook ['rag-basic.ipynb'](rag-basic.ipynb) and run it. 