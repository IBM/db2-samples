/**
 * The Count class is a small struture that just holds the number of inserted/updated/deleted rows.  It
 * also holds an updateInterval, which is the last time the corresponding value was updated.
 *
 * @author tjacopi
 *
 */
public class Count {

    protected int rowsInserted = 0;
    protected int rowsDeleted = 0;
    protected int rowsUpdated = 0;
    protected int lastInsertInterval  = 0;
    protected int lastUpdateInterval  = 0;
    protected int lastDeleteInterval  = 0;

    /*
     * Adds another Count object to this one.  The update interval in the new count is assumed to be latest.
     * @param  c             The count to add.
     * @param intervalToken  Treat the updates as from this interval.
     */
    public void add(Count c, int intervalToken) {
      if (c.rowsInserted > 0) {
        rowsInserted = rowsInserted + c.rowsInserted;
        lastInsertInterval = intervalToken;
      };
      if (c.rowsDeleted > 0) {
        rowsDeleted = rowsDeleted + c.rowsDeleted;
        lastDeleteInterval = intervalToken;
      };
      if (c.rowsUpdated > 0) {
        rowsUpdated = rowsUpdated + c.rowsUpdated;
        lastUpdateInterval = intervalToken;
      };
    }

}
