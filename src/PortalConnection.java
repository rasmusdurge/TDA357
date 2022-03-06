
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    // Set this to e.g. "portal" if you have created a database named portal
    // Leave it blank to use the default database of your database user
    static final String DBNAME = "";
    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/"+DBNAME;
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://brage.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";


    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){

        try(PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO REGISTRATIONS VALUES(?,?)");){
            ps.setString(1,student);
            ps.setString(2, courseCode);
            ps.executeUpdate();
            return "{\"success\":true\"}";

        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+ getError(e)+"\"}";
        }
        // placeholder, remove along with this comment.
      //return "{\"success\":false, \"error\":\"Registration is not implemented yet :(\"}";
      
      // Here's a bit of useful code, use it or delete it 
      // } catch (SQLException e) {
      //    return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
      // }     
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode) {
        //DELETE FROM Registrations WHERE Student = '1111111111' AND course = 'CCC333';

        try (PreparedStatement ps2 = conn.prepareStatement(
                "DELETE FROM REGISTRATIONS WHERE student = ? AND course = ?");) {
            ps2.setString(1, student);
            ps2.setString(2, courseCode);
            int n = 0;
            n = ps2.executeUpdate();
            if (n >= 1) {
                System.out.println("Deleted object" + student + ',' + courseCode);
                return "{\"success\":true\"}";
            }
            else {
                System.out.println("Student is not in registrations");
                return "{\"success\":false\"}";
            }
        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+ getError(e)+"\"}";
        }


        //return "{\"success\":false, \"error\":\"Unregistration is not implemented yet :(\"}";

    }



    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException{
        
        try(PreparedStatement st = conn.prepareStatement(
            // replace this with something more useful
            "SELECT jsonb_build_object('student',idnr,'name',name) AS jsondata FROM BasicInformation WHERE idnr=?"
            );){
            
            st.setString(1, student);
            
            ResultSet rs = st.executeQuery();
            
            if(rs.next())
              return rs.getString("jsondata");
            else
              return "{\"student\":\"does not exist :(\"}"; 
            
        } 
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}