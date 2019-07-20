
 /* JDBC Stored Procedure SSKORSE.sample
 * 
 * param directory
 * @param extension
 * @param subfolder
 * @param File_List
 */ 
 
import java.util.*;
import java.sql.*;
import java.io.*;
import java.io.File;

public class sample
{
    /**
     *
     * @param  WrapperName
     * @param  directory
     * @param  extension
     * @param  subfolder
     * @param  rs1
     * @exception  SQLException
     * @exception  Exception
     */
    public static void get_Nicknames (String WrapperName,
                                      String directory,
                                      String extension,
                                      String subfolder,
                                      ResultSet[] rs1 ) throws SQLException, Exception
    {
        Connection con = DriverManager.getConnection("jdbc:default:connection");        // database connection
        PreparedStatement stmt = null;
        String info = null;                                                             // for the user message
        String sql = null;                                                              // SQL - Statement
        Vector files = new Vector();                                                    // stores the files
		Stack dirs = new Stack();                                                       // stores the directories
		File startdir = new File(directory);                                            // start directory
		String result = null;                                                           // xml - document for the files
	
	                        	                      	
        if ( startdir.isDirectory() ){                                                  // if startdirectory exists
                dirs.push( new File(directory) );										// add directory to the stack
        } else {
	    info = "Directory <" + directory + "> does not exist!";							// else build message for the user
		}
	
        while ( dirs.size() > 0 ) {                                                     // gets all the files and put them into the vector files
	        File dirFiles = (File) dirs.pop();
	        String s[] = dirFiles.list();
	        if ( s != null ){
		        for ( int i = 0; i < s.length; i++ ) {
		        	File file = new File( dirFiles.getAbsolutePath() + File.separator + s[i] );
		            if (  subfolder.equalsIgnoreCase("Y") && file.isDirectory() ){		// if parameter 'subfolder' = 'Y' search subfolders
			        	dirs.push( file );
		            }
		            else if ( (s[i].length() >= extension.length() && s[i].substring(s[i].length() - extension.length(), s[i].length()).equalsIgnoreCase(extension)) ){
		                files.addElement( file );										// if file is valid, add to the vector containing the files
		            }
		        }
	        }
        }
        if (files.size() > 0) {															// if files found, build XML - Document valid to FederatedFromXML.dtd
                result = XMLBuild(files);
        }																				
        else if (info == null) 															// else build message for the user
        	info = "No files with extension <" + extension + "> found in directory <" + directory + ">!";
        if (result != null) {															// if files were found - build SQL-Query to pass them
	        sql = "WITH T(XMLDocument, UserInfo) AS (VALUES(CAST('" + result + "' AS BLOB), CAST(NULL AS VARCHAR(100)))) SELECT * FROM T";
	}else{																				// else - build SQL-Query to pass message for user 
	        sql = "WITH T(XMLDocument, UserInfo) AS (VALUES(CAST(NULL AS BLOB), CAST('" + info + "' AS VARCHAR(100)))) SELECT * FROM T";
	}
	stmt = con.prepareStatement( sql );													// Connection prepare Statement
	rs1[0] = stmt.executeQuery();														// execute Query
	con.close();																		// close Statement
	}

    private static String XMLBuild(Vector files) {                                      // builds the xml document for the files

        	StringBuffer xml = new StringBuffer("\n<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");	
		xml.append("<federatedObjects> \n");											// start with XML-Version + federatedObject tag
		
		for ( int i = 0; i < files.size(); i++ ) {										// for all found files do
				
		    StringBuffer column = new StringBuffer("");									// StringBuffer for the column tag
				
		    try {
		        FileReader in = new FileReader((File)files.elementAt(i));				// build FileReader for the file
		        BufferedReader br = new BufferedReader(in);								// build BufferedReader for the file
                String colContent = null;												// build String for the content of the columns
                int x = 1;																// add iterator for the number of columns
		        try {
		
		            String line = br.readLine();										// read the first line of the file
		            if (line != null) {								
		                while (line.indexOf(',') != -1) {								// if there's still more then one column left
                      	        colContent = line.substring(0, line.indexOf(','));		// get content of the column + build column tag
                      	        
		                        column = column.append("\n\t\t<column datatype=\"varchar\" length=\"" + colContent.length()
		                                        + "\" precision=\"precision\" scale=\"scale\" nullable=\"Y\" columnInDDL=\"N\""
		                                        + " updateable=\"Y\">\n\t\t\t<name>Column_" + x + "</name>\n\t\t</column>");
		                                        
		                        line = line.substring(line.indexOf(',') + 1);			// get the columns which are left
		                        x++;													// iterate number of columns
		                }
				    x++;
		            }
		            if (x > 1) {														// build column tag for the last column
		            	
		                column = column.append("\n\t\t<column datatype=\"varchar\" length=\"" + line.length()
		                                        + "\" precision=\"precision\" scale=\"scale\" nullable=\"Y\" columnInDDL=\"N\""
		                                        + " updateable=\"N\">\n\t\t\t<name>Column_" + (x-1) + "</name>\n\t\t</column>");
		            }
		
		        }catch (IOException io) {												// if IOException appears
		            System.out.println("Input/Output Exception while reading files for XMLBuild");	
		        }
		    } catch (FileNotFoundException fnfw) {										// if FileNotFoundExcsption appears
		        System.err.println("File not found Exception in Method XMLBuild()");
	        }
				
			xml.append("\t<nickname columnsInDDL=\"N\"> \n\t\t<name>");					// build nickname tag
			String h = (files.elementAt(i).toString());									// add name
			xml.append(h.substring(h.lastIndexOf(File.separator) + 1, h.lastIndexOf(".")));
			xml.append("</name> \n\t\t<option name = \"FILE_PATH\">");					// add nickname option 'FILE_PATH'
			xml.append((String)((File)files.elementAt(i)).getAbsolutePath());
			xml.append("</option>" + column.toString() + "\n\t</nickname>\n");			// add column tag

		}			
	
		xml.append("</federatedObjects>");												// close federatedObject tag
		return xml.toString();															// return XML - Document as String
   }
}
