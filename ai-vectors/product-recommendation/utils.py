import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import os
import ast
import numpy as np
import matplotlib.pyplot as plt
from sklearn.manifold import TSNE

def display_sku_images(sku_list, image_folder='images', image_ext='.jpeg', n_cols=3):
    """
    Display SKU images in a grid.

    Args:
        sku_list (list of str): List of SKUs.
        image_folder (str): Folder where image files are stored.
        image_ext (str): File extension of images (e.g., '.jpeg').
        n_cols (int): Number of images per row.
    """
    n_rows = (len(sku_list) + n_cols - 1) // n_cols  # Ceiling division

    plt.figure(figsize=(n_cols * 4, n_rows * 4))

    for idx, sku in enumerate(sku_list):
        image_path = os.path.join(image_folder, f"{sku}{image_ext}")
        plt.subplot(n_rows, n_cols, idx + 1)

        if os.path.exists(image_path):
            img = mpimg.imread(image_path)
            plt.imshow(img)
            plt.title(sku, fontsize=10)
        else:
            plt.text(0.5, 0.5, "Image not found", ha='center', va='center')

        plt.axis('off')

    plt.tight_layout()
    plt.show()
    
    
def get_men_shoes_sql():
    return """ 
    SELECT SKU, PRODUCT_NAME, BRAND, TYPE, MATERIAL, COLOR, WEATHER_RESISTANCE, ARCH_SUPPORT, PRICE, RATING, CITY
    FROM SQ_SHOES 
    WHERE CLASS = 'Men' AND Size = 12 
    FETCH FIRST 6 ROWS ONLY
    """
    
# shoe_queries.py

def get_similar_shoes_sql():
    return """
    SELECT 
        SKU, 
        PRODUCT_NAME, 
        BRAND, 
        TYPE, 
        MATERIAL, 
        COLOR, 
        WEATHER_RESISTANCE, 
        ARCH_SUPPORT, 
        PRICE, 
        RATING,
        VECTOR_DISTANCE(
            (SELECT EMBEDDING FROM SQ_SHOES WHERE SKU = :my_choice_sku), 
            EMBEDDING, 
            EUCLIDEAN
        ) AS DISTANCE
    FROM 
        SQ_SHOES
    WHERE 
        SKU <> :my_choice_sku
        AND CITY = 'Toronto'
        AND SIZE = 12
        AND CLASS = 'Men'
    ORDER BY 
        DISTANCE ASC
    FETCH FIRST 3 ROWS ONLY
    """

# shoe_queries.py

def get_distance_for_sku_list_sql(sku_sql_in):
    """
    Returns SQL query that retrieves shoes by SKU list with vector distances
    relative to :my_choice_sku.

    Args:
        sku_sql_in (str): A string of comma-separated quoted SKUs for SQL IN clause.
                          e.g., "'LOO-1396', 'STR-7223'"
    """
    return f"""
    SELECT 
        SKU, 
        PRODUCT_NAME, 
        BRAND, 
        TYPE, 
        MATERIAL, 
        COLOR, 
        WEATHER_RESISTANCE, 
        ARCH_SUPPORT, 
        PRICE, 
        RATING,
        VECTOR_DISTANCE(
            (SELECT EMBEDDING FROM SQ_SHOES WHERE SKU = :my_choice_sku), 
            EMBEDDING, 
            EUCLIDEAN
        ) AS DISTANCE
    FROM 
        SQ_SHOES
    WHERE 
        SKU IN ({sku_sql_in})
    ORDER BY 
        DISTANCE ASC
    """
    
# shoe_ddl.py

def get_create_sq_shoes_table_sql():
    return """
    CREATE TABLE SQ_SHOES (
        SKU VARCHAR(8),
        PRODUCT_NAME VARCHAR(23),
        BRAND VARCHAR(9),
        CLASS VARCHAR(5),
        TYPE VARCHAR(7),
        MATERIAL VARCHAR(9),
        COLOR VARCHAR(5),
        WEATHER_RESISTANCE VARCHAR(10),
        ARCH_SUPPORT VARCHAR(4),
        SIZE FLOAT,
        PRICE FLOAT,
        RATING FLOAT,
        STORE_ID BIGINT,
        CITY VARCHAR(7),
        EMBEDDING VECTOR(1024,FLOAT32)
    );
    """

def get_create_sq_shoes_table_data_only():
    return """
    CREATE TABLE SQ_SHOES (
        SKU VARCHAR(8),
        PRODUCT_NAME VARCHAR(23),
        BRAND VARCHAR(9),
        CLASS VARCHAR(5),
        TYPE VARCHAR(7),
        MATERIAL VARCHAR(9),
        COLOR VARCHAR(5),
        WEATHER_RESISTANCE VARCHAR(10),
        ARCH_SUPPORT VARCHAR(4),
        SIZE FLOAT,
        PRICE FLOAT,
        RATING FLOAT,
        STORE_ID BIGINT,
        CITY VARCHAR(7)
    );
    """

# shoe_queries.py

def get_shoe_by_sku_sql():
    return """
    SELECT 
        PRODUCT_NAME, 
        BRAND, 
        TYPE, 
        MATERIAL, 
        COLOR, 
        WEATHER_RESISTANCE, 
        ARCH_SUPPORT, 
        PRICE, 
        RATING
    FROM 
        SQ_SHOES 
    WHERE 
        SKU = :my_choice_sku
    """

# shoe_query.py

def get_similarity_query(sku_sql_in: str) -> str:
    sql = f"""
    SELECT 
        SKU, 
        PRODUCT_NAME, 
        VECTOR_DISTANCE(
            (SELECT EMBEDDING FROM SQ_SHOES WHERE SKU = :my_choice_sku), 
            EMBEDDING, 
            EUCLIDEAN
        ) AS DISTANCE,
        VECTOR_SERIALIZE(EMBEDDING) AS EMBEDDING 
    FROM 
        SQ_SHOES
    WHERE 
        SKU IN ({sku_sql_in})
    """
    return sql

def plot_similarity_tsne(top_matching_vectors, my_choice_sku):
    # Parse vector strings to list of floats
    top_matching_vectors['embedding_list'] = top_matching_vectors['EMBEDDING'].apply(ast.literal_eval)

    # Convert to 2D numpy array
    X = np.array(top_matching_vectors['embedding_list'].tolist())

    # Run t-SNE
    tsne = TSNE(n_components=2, random_state=42, perplexity=5)
    X_embedded = tsne.fit_transform(X)

    # Find index of my_choice_sku
    target_idx = top_matching_vectors[top_matching_vectors['SKU'] == my_choice_sku].index[0]
    target_point = X_embedded[target_idx]

    # Plot setup
    plt.figure(figsize=(10, 8))
    plt.scatter(X_embedded[:, 0], X_embedded[:, 1], color='skyblue')

    # Draw lines and annotate
    for i, row in top_matching_vectors.iterrows():
        point = X_embedded[i]
        sku = row['SKU']
        product_name = row['PRODUCT_NAME']
        distance = row['DISTANCE']

        if sku != my_choice_sku:
            plt.plot([target_point[0], point[0]], [target_point[1], point[1]],
                     linestyle='--', color='gray', linewidth=0.8)
            mid_x = (target_point[0] + point[0]) / 2
            mid_y = (target_point[1] + point[1]) / 2
            plt.text(mid_x, mid_y, f"{distance:.2f}", fontsize=8, color='blue', ha='center')

        label_color = 'red' if sku == my_choice_sku else 'black'
        font_weight = 'bold' if sku == my_choice_sku else 'normal'
        plt.annotate(str(product_name), (point[0], point[1]), fontsize=9, ha='right',
                     color=label_color, fontweight=font_weight)

    # Highlight selected SKU with red circle
    plt.scatter(target_point[0], target_point[1], s=200, facecolors='none',
                edgecolors='red', linewidths=2)

    # Remove all extras for clean visual
    plt.grid(False)
    plt.xlabel("")
    plt.ylabel("")
    plt.xticks([])
    plt.yticks([])
    ax = plt.gca()
    for spine in ax.spines.values():
        spine.set_visible(False)

    plt.title(f"Vector Distance Between the Recommended Shoes and Sample Shoe {my_choice_sku}")
    plt.tight_layout()
    plt.show()