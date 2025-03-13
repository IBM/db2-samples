from langchain.vectorstores import VectorStore
from langchain.schema import Document
from typing import List, Type, Optional
import ibm_db
from ibm_watsonx_ai.foundation_models import Embeddings
import os
from dotenv import load_dotenv

# Module-level variable to hold the database connection
db2_connection = None
load_dotenv(os.getcwd()+"/.env", override=True)
load_dotenv(os.getcwd()+"/sql.env", override=True)

def get_db2_connection():
    global db2_connection
     
    conn_str = (
        f"DATABASE={os.getenv('database')};"
        f"HOSTNAME={os.getenv('hostname')};"
        f"PORT={os.getenv('port')};"
        f"PROTOCOL=TCPIP;"
        f"UID={os.getenv('uid')};"
        f"PWD={os.getenv('pwd')};"
    )
    
    db2_connection = ibm_db.connect(conn_str, "", "")
    if db2_connection:
        print("Connected to Db2 successfully.")
    else:
        print("Failed to connect to Db2.")
    
    return db2_connection

def close_db2_connection():
    if db2_connection:
        try:
            ibm_db.close(db2_connection)
            print("Disconnected from Db2 successfully.")
        except Exception as e:
            print(f"Error occurred while disconnecting: {e}")
    else:
        print("No active connection to close.")
        
def initialize_db():
    # Retrieve the SQL queries
    drop_table_query = os.getenv('SQL_DROP_TABLE')
    create_table_query = os.getenv('SQL_CREATE_TABLE')

    if not drop_table_query or not create_table_query:
        raise ValueError("One or more SQL query environment variables are not set.")
    
    try:
        # Drop the table if it exists
        ibm_db.exec_immediate(db2_connection, drop_table_query)
        print("Table 'embeddings' dropped successfully (if it existed).")
        
        # Create the new table
        ibm_db.exec_immediate(db2_connection, create_table_query)
        print("Table 'embeddings' created successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")
        
def cleanup_db():
    # Retrieve the SQL queries
    drop_table_query = os.getenv('SQL_DROP_TABLE')

    if not drop_table_query:
        raise ValueError("One or more SQL query environment variables are not set.")
    
    try:
        # Drop the table if it exists
        ibm_db.exec_immediate(db2_connection, drop_table_query)
        print("Table 'embeddings' dropped successfully (if it existed).")
    except Exception as e:
        print(f"An error occurred: {e}")

class Db2VectorStore(VectorStore):
    def __init__(self, embedding_function, k=5):
        self.conn = db2_connection
        self.embedding_function = embedding_function
        self.k = k  # Store the value of k
        self.sql_insert_template = os.getenv('SQL_INSERT')
        self.sql_distance_template = os.getenv('SQL_DISTANCE')
        if not self.sql_insert_template or not self.sql_distance_template:
            raise ValueError("SQL environment variable(s) not set.")

    def add_documents(self, documents: List[Document]) -> List[int]:
        ids = []
        for doc in documents:
            # Generate embedding for the document content
            embedding_vector = self.embedding_function.embed_query(doc.page_content)
            embedding_vector_str = ", ".join(map(str, embedding_vector))  # Convert list to string

            # print(embedding_vector_str)
            
            # Convert embedding vector to binary format            
            # Prepare metadata
            metadata = doc.metadata
            source = metadata.get("source", "")
            title = metadata.get("title", "")
            
            insert_query = self.sql_insert_template.format(embedding_vector_str=embedding_vector_str)
            
            # print(insert_query)
            stmt = ibm_db.prepare(self.conn, insert_query)
            ibm_db.bind_param(stmt, 1, doc.page_content)
            ibm_db.bind_param(stmt, 2, source)
            ibm_db.bind_param(stmt, 3, title)
            # ibm_db.bind_param(stmt, 4, embedding_str)
            ibm_db.execute(stmt)
            
            # Retrieve the generated id
            select_query = "SELECT IDENTITY_VAL_LOCAL() AS id FROM SYSIBM.SYSDUMMY1"
            stmt = ibm_db.exec_immediate(self.conn, select_query)
            result = ibm_db.fetch_assoc(stmt)
            generated_id = result['ID']
            ids.append(generated_id)
        
        return ids

    def similarity_search(self, query: str, top_k: int = None) -> List[Document]:
        if top_k is None:
            top_k = self.k  # Use the instance's k value if top_k is not provided
        
        # Generate query embedding
        # print(query)
        query_embedding = self.embedding_function.embed_query(query)
    
        # Convert embedding to string format
        query_embedding_str = ", ".join(map(str, query_embedding))
    
        # Construct SQL query
        sql_distance = self.sql_distance_template.format(query_embedding_str=query_embedding_str, top_k=top_k)
        
        # print(sql_distance)
    
        # Execute SQL query
        stmt = ibm_db.exec_immediate(self.conn, sql_distance)
    
        # Fetch and process results
        results = []
        row = ibm_db.fetch_assoc(stmt)
        while row:
            doc = Document(page_content=row['CONTENT'], metadata={'source': row['SOURCE'], 'title': row['TITLE'], 'distance': row['DISTANCE']})
            results.append(doc)
            row = ibm_db.fetch_assoc(stmt)
    
        return results

    @classmethod
    def from_texts(cls: Type[VectorStore], texts: List[str], embedding: Embeddings, metadatas: Optional[List[dict]] = None, **kwargs) -> VectorStore:
        # Create Document objects from texts and metadatas
        documents = []
        for i, text in enumerate(texts):
            metadata = metadatas[i] if metadatas and i < len(metadatas) else {}
            documents.append(Document(page_content=text, metadata=metadata))
        # Initialize the vector store
        db2_connection = kwargs.get('db2_connection')
        vector_store = cls(db2_connection=db2_connection, embedding_function=embedding)
        # Add documents to the vector store
        vector_store.add_documents(documents)
        return vector_store