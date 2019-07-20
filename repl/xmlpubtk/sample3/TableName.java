
/**
 * The TableName class is a class that holds an owner and table name.
 *
 * @author tjacopi
 *
 */
public class TableName {

    protected String ownerName = null;
    protected String tblName = null;

    public TableName() {
    }

    public TableName(String owner, String tName) {
      ownerName = owner;
      tblName = tName;
    }

    public int hashCode() {
      return tblName.hashCode();
    }

    public String toString() {
      return ownerName + "." + tblName;
    }

    public boolean equals(Object obj) {
      boolean rc = (this == obj);
      if (!rc && obj != null && obj instanceof TableName) {
        TableName tObj = (TableName) obj;
        if ( (ownerName == null && tObj.ownerName != null) ||
             (ownerName != null && tObj.ownerName == null) ) {
          rc = false;                                      // One obj has null owner name, other does not
        } else {
          if (ownerName != null && ownerName.equals(tObj.ownerName) ) {
            rc = tblName.equals(tObj.tblName);
          } else {
            rc = false;                                    // owner names not equal
          }
        }
      }

      return rc;
    }
}
