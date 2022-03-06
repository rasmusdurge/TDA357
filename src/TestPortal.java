import java.util.concurrent.TimeUnit;

public class TestPortal {

   // enable this to make pretty printing a bit more compact
   private static final boolean COMPACT_OBJECTS = false;

   // This class creates a portal connection and runs a few operation

   public static void main(String[] args) {
      try{
        PortalConnection c = new PortalConnection();
          System.out.println("Unregister student from limited course with queue");pause();
          System.out.println(c.unregister("1111111111", "CCC333"));

        System.out.println("Get info about student\n"+c.getInfo("2222222222"));
        TimeUnit.SECONDS.sleep(1);

        System.out.println("Register student to course"); pause();
        System.out.println(c.register("2222222222", "CCC111"));

          System.out.println("Get info about student");pause();
        System.out.println(c.getInfo("2222222222"));

        System.out.println("Register student to same course again");pause();
         System.out.println(c.register("2222222222", "CCC111"));

          System.out.println("Unregister student form course"); pause();
          System.out.println(c.unregister("2222222222", "CCC111"));

          System.out.println("Unregister student form course again");pause();
          System.out.println(c.unregister("2222222222", "CCC111"));

          System.out.println("Register student to course without having the prerequisite");pause();
          System.out.println(c.register("2222222222", "CCC555"));

          System.out.println("Unregister student from limited course with queue");pause();
          System.out.println(c.unregister("1111111111", "CCC333"));

          System.out.println("Register student from limited course with queue");pause();
          System.out.println(c.register("1111111111", "CCC333"));

          System.out.println("Unregister student from limited course with queue");pause();
            System.out.println(c.unregister("1111111111", "CCC333"));

          System.out.println("Register student from limited course with queue");pause();
          System.out.println(c.register("1111111111", "CCC333"));

          System.out.println("Unregister student form overfull course");pause();
          System.out.println(c.unregister("1111111111", "CCC222"));

          System.out.println("Remove all student via SQL injection");pause();
          System.out.println(c.unregister("1111111111", "test' OR 't1'='t1"));
          /*
            -List info for a student.
            -Register a student for an unrestricted course, and check that he/she ends up registered (print info again).
            -Register the same student for the same course again, and check that you get an error response.
            -Unregister the student from the course, and then unregister him/her again from the same course. Check that the student is no longer registered and that the second unregistration gives an error response.
            -Register the student for a course that he/she doesn't have the prerequisites for, and check that an error is generated.
            -Unregister a student from a restricted course that he/she is registered to, and which has at least two students in the queue. Register again to the same course and check that the student gets the correct (last) position in the waiting list.
            -Unregister and re-register the same student for the same restricted course, and check that the student is first removed and then ends up in the same position as before (last).
            Unregister a student from an overfull course, i.e. one with more students registered than there are places on the course (you need to set this situation up in the database directly). Check that no student was moved from the queue to being registered as a result.
            Unregister with the SQL injection you introduced, causing all (or almost all?) registrations to disappear.
             */











          //DELETE FROM Waiting WHERE position=1 AND course='x'' OR ''a''=''a'


         // String code1 = "x' OR 'a'='a";
         // DELETE FROM Waiting WHERE position=1 AND course='x'' OR ''a''=''a'
      //      System.out.println(c.unregister("1111111111", "test' OR 't1'='t1"));
        //    pause();



      } catch (ClassNotFoundException e) {
         System.err.println("ERROR!\nYou do not have the Postgres JDBC driver (e.g. postgresql-42.2.18.jar) in your runtime classpath!");
      } catch (Exception e) {
         e.printStackTrace();
      }
   }



   public static void pause() throws Exception{
     System.out.println("PRESS ENTER");
     while(System.in.read() != '\n');
   }

   // This is a truly horrible and bug-riddled hack for printing JSON.
   // It is used only to avoid relying on additional libraries.
   // If you are a student, please avert your eyes.
   public static void prettyPrint(String json){
      System.out.print("Raw JSON:");
      System.out.println(json);
      System.out.println("Pretty-printed (possibly broken):");

      int indent = 0;
      json = json.replaceAll("\\r?\\n", " ");
      json = json.replaceAll(" +", " "); // This might change JSON string values :(
      json = json.replaceAll(" *, *", ","); // So can this

      for(char c : json.toCharArray()){
        if (c == '}' || c == ']') {
          indent -= 2;
          breakline(indent); // This will break string values with } and ]
        }

        System.out.print(c);

        if (c == '[' || c == '{') {
          indent += 2;
          breakline(indent);
        } else if (c == ',' && !COMPACT_OBJECTS)
           breakline(indent);
      }

      System.out.println();
   }

   public static void breakline(int indent){
     System.out.println();
     for(int i = 0; i < indent; i++)
       System.out.print(" ");
   }   
}