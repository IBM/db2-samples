# Vector Indexes in Db2 (Early Access Program)

This README provides step-by-step instructions for exploring the new Vector Indexes feature introduced in IBM Db2 as part of the Early Access Program (EAP).

Vector Indexes enable efficient similarity search over high-dimensional vector data, supporting use cases such as AI-powered retrieval, recommendation systems, and semantic search.

⚠️ Vector Index functionality is only available in the Db2 Early Access Program (EAP 97). It is not included in general availability (GA) releases.

## Before You Begin

To understand the capabilities, limitations, and prerequisites of the Vector Index feature in Db2, please read the official Early Access Program documentation.

## Workflow Overview

This guide walks you through the following steps:
1. Downloading sample vector data
2. Formatting the data for Db2 LOAD
3. Creating a vector table
4. Loading the vector data into Db2
5. Creating a vector index
6. Querying the vector index
7. Dropping the vector index

## Sample Dataset

The sample vector data used in this guide is the SIFT1M dataset which is commonly used for benchmarking similarity search algorithms. SIFT1M consists of:
* 1 million vectors
* Each vector has 128 dimensions

## Prerequisites and Environment Setup

Before running the example, ensure the following prerequisites are met:

* CPU: AMD64 with AVX2
* Operating System: RHEL 9.4
* Python: Version 3+ with pip
* Tools: curl (for downloading the dataset)
* Db2: Access to the Early Access Program (EAP 97)

Next, download all the files contained in this directory to your local machine.

## Step-by-Step Instructions

### Step 1: Download and Format Sample Vector Data

Run the provided shell script to download the SIFT1M dataset and convert it into a CSV format suitable for Db2 LOAD:

```bash
./downloadAndFormatVectorData.sh
```

Output:
* `sift_base.csv` containing 1M rows of 128-dimensional vectors.
* `sift_query_100.csv` containing 100 randomly selected vectors from the SIFT1M dataset.
* `sift_groundtruth_100.csv` containing the top 100 nearest neighbor IDs (from `sift_base.csv`) for each query, ordered by increasing squared Euclidean distance.

_Note: The script may take a couple of minutes to complete depending on your network speed and system performance._

### Step 2: Enable Vector Index Feature in Db2

_Reminder: Make sure you've reviewed the EAP documentation to confirm your environment meets all prerequisites._

Set the required registry variable to enable vector indexing:

```bash
db2set DB2_VECTOR_INDEXING=TRUE
```

The instance does not need to be restarted to take effect.

### Step 3: Create the Vector Tables and Load Data

This step sets up the tables for evaluating approximate nearest neighbor (ANN) search performance.

#### Create the Vector Table

Create a table with an ID and a vector column:

```sql
CREATE TABLE SIFT_BASE (
   ID INT NOT NULL,
   EMBEDDING VECTOR(128, FLOAT32) NOT NULL
)
```

Load the formatted CSV data into the table:

```sql
LOAD FROM sift_base.csv OF DEL
INSERT INTO SIFT_BASE
```

#### Create the Query Table

```sql
CREATE TABLE SIFT_QUERY (
   ID INT NOT NULL,
   EMBEDDING VECTOR(128, FLOAT32) NOT NULL
)
```

Load the query vectors from the CSV file:

```sql
LOAD FROM sift_query_100.csv OF DEL
INSERT INTO SIFT_QUERY
```

### Step 4: Create Vector Index and Collect Statistics

Create a vector index using Euclidean distance:

```sql
CREATE VECTOR INDEX SIFT_EUCLIDEAN
ON SIFT_BASE (EMBEDDING)
WITH DISTANCE EUCLIDEAN
```

_Note: Index creation will take a while to complete and will depend on your system performance._

RUNSTATS to optimize query performance and allow the use of the index over a brute-force search:

```sql
RUNSTATS ON TABLE SIFT_BASE FOR INDEXES ALL
```

### Step 5: Query Using Approximate Nearest Neighbor Search and Compare with Ground Truth

Retrieve the top 5 approximate nearest neighbors for a sample query (e.g. first query in SIFT_QUERY table):

```sql
SELECT
   ID,
   VECTOR_DISTANCE(
      (SELECT EMBEDDING
       FROM SIFT_QUERY
       FETCH FIRST 1 ROWS ONLY),
      EMBEDDING,
      EUCLIDEAN)
   AS DISTANCE
   FROM SIFT_BASE
   ORDER BY DISTANCE
   FETCH APPROX FIRST 10 ROWS ONLY
```

FETCH *APPROX* FIRST enables approximate search for faster results.

### Step 6: Compare Brute-Force Search and Groundtruth vs. ANN Search

To run a brute-force search (exact nearest neighbors), use FETCH EXACT clause:

```sql
SELECT
   ID,
   VECTOR_DISTANCE(
      (SELECT EMBEDDING
       FROM SIFT_QUERY
       FETCH FIRST 1 ROWS ONLY),
      EMBEDDING,
      EUCLIDEAN)
   AS DISTANCE
FROM SIFT_BASE
ORDER BY DISTANCE
FETCH EXACT FIRST 10 ROWS ONLY
```

Comparison:

* Compare the result set above with the ANN results from Step 5. Are the top-k neighbors the same?
* You can also verify against the ground truth by checking the query ID:

```sql
SELECT ID
FROM SIFT_QUERY
FETCH FIRST 1 ROWS ONLY
```

Then use the query ID to look up the expected nearest neighbors in the ground
truth file:

```bash
grep -E "^<query_id>," sift_groundtruth_100.csv
```

Evaluation:

* Accuracy: How many of the ANN results match the brute-force or ground truth results (e.g., recall@k)?
* Latency: Measure query execution time for each method
* Resource Usage: Monitor CPU and memory consumption during query execution

### Step 7: Cleanup

After completing your evaluation, you can clean up the environment by dropping the vector index and tables:

```sql
DROP INDEX SIFT_EUCLIDEAN
```

```sql
DROP TABLE SIFT_BASE
DROP TABLE SIFT_QUERY
DROP TABLE SIFT_GROUNDTRUTH
```

## Conclusion and Key Takeaways

This demo guided you through the process of using Vector Indexes in Db2, showcasing how to prepare vector data, enable the feature, perform similarity search using SQL, and compare against a brute force search.

### Key Takeaways

* Vector Indexes introduce native support for high-dimensional similarity search in Db2, enabling AI-driven use cases without external tooling.
* The SIFT1M dataset serves as a practical benchmark for testing performance and accuracy of vector search.
* Approximate search using FETCH APPROX FIRST provides fast results, ideal for large-scale datasets where latency matters more than exact precision.
