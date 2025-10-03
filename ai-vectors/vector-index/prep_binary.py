import numpy as np
import random

import numpy as np

def read_fvecs(filename):
    with open(filename, 'rb') as f:
        dim = np.fromfile(f, dtype=np.int32, count=1)[0]
        f.seek(0)
        data = np.fromfile(f, dtype=np.float32)
        data = data.reshape(-1, dim + 1)[:, 1:]
    return data

def read_ivecs(filename):
    with open(filename, 'rb') as f:
        dim = np.fromfile(f, dtype=np.int32, count=1)[0]
        f.seek(0)
        data = np.fromfile(f, dtype=np.int32)
        data = data.reshape(-1, dim + 1)[:, 1:]
    return data

def prepend_indexes_to_lines(file_path, indexes):
    """
    Reads a file and prepends each line with the corresponding index from the indexes array.

    Parameters:
    - file_path (str): Path to the input file.
    - indexes (list): List of indexes to prepend to each line.

    Returns:
    - list: A list of strings with indexes prepended.
    """
    with open(file_path, 'r') as file:
        lines = file.readlines()

    if len(lines) != len(indexes):
        raise ValueError("Number of indexes must match the number of lines in the file.")

    modified_lines = [f"{index},\"[{line.rstrip()}]\"\n" for index, line in zip(indexes, lines)]

    with open(file_path, 'w') as file:
        file.writelines(modified_lines)

# ==== Load data ====
print("Loading base vectors ...")
base = read_fvecs("sift/sift_base.fvecs")        # (1,000,000 x 128)

print("Loading queries and ground truth ...")
queries = read_fvecs("sift/sift_query.fvecs")   # (10,000 x 128)
groundtruth = read_ivecs("sift/sift_groundtruth.ivecs")  # (10,000 x 100)

# ==== Randomly sample 100 queries ====
selected_indices = np.random.choice(len(queries), size=100, replace=False)
queries_sampled = queries[selected_indices]
gt_sampled = groundtruth[selected_indices]

# ==== Export to CSV with brackets ====
print("Saving sift_base.csv ...")
np.savetxt("sift_base.csv", base, delimiter=",")
prepend_indexes_to_lines("sift_base.csv", range(0,1000000))

print("Saving sift_query_100.csv ...")
np.savetxt("sift_query_100.csv", queries_sampled, delimiter=",")
prepend_indexes_to_lines("sift_query_100.csv", selected_indices)

print("Saving sift_groundtruth_100.csv ...")
np.savetxt("sift_groundtruth_100.csv", gt_sampled, fmt='%d', delimiter=",")
prepend_indexes_to_lines("sift_groundtruth_100.csv", selected_indices)

print("Done! Files saved:")
print("- sift_base.csv")
print("- sift_query_100.csv")
print("- sift_groundtruth_100.csv")
