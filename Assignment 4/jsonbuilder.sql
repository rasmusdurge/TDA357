--JSON FILE
\set QUIET true
SET client_min_messages TO WARNING; -- Less talk please.
-- Use this instead of drop schema if running on the Chalmers Postgres server
-- DROP OWNED BY TDA357_XXX CASCADE;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false


-- \ir is for include relative, it will run files in the same directory as this file
-- Note that these are not SQL statements but rather Postgres commands (no terminating ;). 
\ir tables.sql
\ir views.sql
\ir inserts.sql
\ir triggers.sql


--Goal: Build a json array with 

--json_build_array
--json object for basicinformation

/*
SELECT 
 jsonb_build_object('idnumber', idnr, 'name',name,'login'
 ,login,'program',program,'branch',branch) AS jsonbasic
FROM Basicinformation;

*/
/*
--object for taken courses
SELECT jsonb_build_object('student',student,'course', course, 'grade', grade) AS jsontaken
FROM Taken;

--object for registered/waiting
SELECT
jsonb_build_object('student',student, 'course',course,'status',status) AS jsonregistrations
FROM Registrations;

--object for path
SELECT 
jsonb_build_object('student' , student , 'mandleft', mandatoryleft,'mathCredits',
mathCredits,'researchCredits',researchCredits,'seminarCourses',seminarCourses,'qualified',qualified)
AS jsonpath
FROM PathToGraduation;
*/






/*

SELECT jsonb_agg(jsonb_build_object('sID',idnr,'name',Basicinformation.name,'login',login,'program',program,'branch',branch, 
		
		'finished',(SELECT jsonb_agg(jsonb_build_object('course', Courses.name,'code',course,'credits',FinishedCourses.credits,'grade',grade))
			FROM FinishedCourses, Courses WHERE Student = Basicinformation.idnr AND Courses.code= FinishedCourses.course) 
		
			,'registered'	,(SELECT (jsonb_agg(jsonb_build_object('coursename',Courses.name,'code',course,'status',status )))
						FROM Registrations, Courses WHERE Student = Basicinformation.idnr AND Courses.code = Registrations.course)
						
						,'seminarCourses', (SELECT seminarCourses from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'mathCredits', (SELECT mathCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'researchCredits', (SELECT researchCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'totalCredits', (SELECT totalCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'canGraduate', (SELECT qualified from pathtograduation WHERE student = Basicinformation.idnr)
								
						))AS student_data
		FROM Basicinformation ;
		

*/		

--One array with comma separated objects
/*
SELECT jsonb_agg(jsonb_build_object('sID',idnr,'name',Basicinformation.name,'login',login,'program',program,'branch',branch,'finished',(SELECT jsonb_agg(jsonb_build_object('course', Courses.name,'code',course,'credits',FinishedCourses.credits,'grade',grade))
			FROM FinishedCourses, Courses WHERE Student = Basicinformation.idnr AND Courses.code= FinishedCourses.course) 
		
			,'registered'	,(SELECT (jsonb_agg(jsonb_build_object('coursename',Courses.name,'code',course,'status',status )))
						FROM Registrations, Courses WHERE Student = Basicinformation.idnr AND Courses.code = Registrations.course)
						
						,'seminarCourses', (SELECT seminarCourses from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'mathCredits', (SELECT mathCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'researchCredits', (SELECT researchCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'totalCredits', (SELECT totalCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'canGraduate', (SELECT qualified from pathtograduation WHERE student = Basicinformation.idnr)
								
						))AS student_data
		FROM Basicinformation ;
*/

--this has multiple rows
/*
SELECT jsonb_build_object('sID',idnr,'name',Basicinformation.name,'login',login,'program',program,'branch',branch,'finished',(SELECT jsonb_agg(jsonb_build_object('course', Courses.name,'code',course,'credits',FinishedCourses.credits,'grade',grade))
			FROM FinishedCourses, Courses WHERE Student = Basicinformation.idnr AND Courses.code= FinishedCourses.course) 
		
			,'registered'	,(SELECT (jsonb_agg(jsonb_build_object('coursename',Courses.name,'code',course,'status',status )))
						FROM Registrations, Courses WHERE Student = Basicinformation.idnr AND Courses.code = Registrations.course)
						
						,'seminarCourses', (SELECT seminarCourses from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'mathCredits', (SELECT mathCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'researchCredits', (SELECT researchCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'totalCredits', (SELECT totalCredits from pathtograduation WHERE student = Basicinformation.idnr)
						
						,'canGraduate', (SELECT qualified from pathtograduation WHERE student = Basicinformation.idnr)
								
						)AS student_data
		FROM Basicinformation ;

*/
/*

SELECT jsonb_build_object ('sID', idnr , ’email’, email,
’posts’, (SELECT COALESCE (jsonb agg (jsonb build object (
’postid’, id, ’time’, created)),
’[ ]’)
FROM Posts WHERE author = Users.uname)
) AS user data
FROM Users;

*/



/*
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Student iformation",
  "type": "object",
  "required": [
    "student",
    "name",
    "login",
    "program",
    "branch",
    "finished",
    "registered",
    "seminarCourses",
    "mathCredits",
    "researchCredits",
    "totalCredits",
    "canGraduate"
  ],
  "properties": {
    "student": {
      "type": "string",
      "minLength": 10,
      "maxLength": 10,
      "title": "A national identification number, 10 digits"
    },
    "name": {
      "type": "string",
      "title": "The name of the student"
    },
    "login": {
      "type": "string",
      "title": "The univerity issued computer login"
    },
    "program": {
      "type": "string",
    },
    "branch": {
      "anyOf":[{"type": "string"},{"type": "null"}],
    },
    "finished": {
      "type": "array",
      "title": "A list of read courses",
      "items": {
        "type": "object",
        "required": [
          "course",
          "code",
          "credits",
          "grade"
        ],
        "properties": {
          "course": {
            "type": "string",
            "title": "Course name"
          },
          "code": {
            "type": "string",
            "minLength": 6,
            "maxLength": 6,
            "title": "Course code"
          },
          "credits": {
            "type": "number",
            "title": "Academic credits"
          },
          "grade": {
            "enum" : ["U", "3", "4", "5"]
          }
        }
      }
    },
    "registered": {
      "type": "array",
      "title": "Registered and waiting courses",
      "items": {
        "type": "object",
        "required": [
          "course",
          "code",
          "status"
        ],
        "properties": {
          "course": {
            "type": "string",
            "title": "Course name"
          },
          "code": {
            "type": "string",
            "minLength": 6,
            "maxLength": 6,
            "title": "Course code"
          },
          "status": {
            "enum" : ["registered", "waiting"],          
            "title": "Registration status"
          },
          "position": {
            "anyOf":[{"type": "number"},{"type": "null"}],         
            "title": "Waiting list position"
          }
        }
      }
    },
    "seminarCourses": {
      "type": "integer",
      "title": "Number of passed seminar courses"
    },
    "mathCredits": {
      "type": "number",
      "title": "Total passed math credits"
    },
    "researchCredits": {
      "type": "number",
      "title": "Total passed research credits"
    },
    "totalCredits": {
      "type": "number",
      "title": "Total passed credits"
    },
    "canGraduate": {
      "type": "boolean",
      "title": "Qualified for graduation"
    }
  }
}

*/


/*

SELECT jsonb_agg (idnr,login):: AS jsonarray FROM Basicinformation;

SELECT 
 jsonb_build_object('idnumber', idnr, 'name',name,'login'
 ,login,'program',program,'branch',branch) AS jsondata
FROM Basicinformation;

*/

