/**
 * The StringWithInterval class is a small struture that just holds a string along with an interval.
 * This is what is in the JTable cells.  The JTable will just call toString() to get the value,
 * and the cell renderer can cast & call getInterval() if we are timeshading.
 *
 * @author tjacopi
 *
 */
public class StringWithInterval {

  public int interval = 0;
  public String string = null;

  public StringWithInterval(String str, int interval) {
    string = str;
    this.interval = interval;
  }

  public int getInterval() {
    return interval;
  }

  public String toString() {
    return string;
  }
}
