create or replace view CourseQueuePositions as(
    select course, student, position as place from waitinglist
);

CREATE or replace FUNCTION trigger_insert() RETURNS trigger as $$
BEGIN

--Check if student exists and course exists
	IF (NOT EXISTS(SELECT idnr FROM Students where NEW.student = idnr) OR 
	   (NOT EXISTS(SELECT code FROM courses where NEW.course = code)))
		THEN RAISE EXCEPTION 'Student is not a student or course is not a course';
	END IF;
	
--Check if student is already registered or in waitinglist
    IF (EXISTS (SELECT student, course FROM Registrations WHERE student = NEW.student and course = NEW.course) )
        THEN RAISE EXCEPTION 'Student is already registered or in waitinglist';
    END IF;
	
--CHECK if course has any prerequisite courses
	IF(EXISTS(SELECT course FROM Prerequisities WHERE NEW.course = Prerequisities.course))
		THEN 

-- Check whether the student has read the prerequisite course / courses
		IF (NOT EXISTS (select student from Prerequisities join passedcourses ON pcourse = passedcourses.course 
			WHERE student = NEW.student and Prerequisities.course = NEW.course))
			THEN RAISE EXCEPTION 'Student has not read the prerequisite course or courses';
		END IF;
	
	END IF;
	
-- Check whether course is limited
	IF (EXISTS (SELECT * FROM LimitedCourses WHERE NEW.course = code))
		THEN
		
-- Check whether limited course has room for an additional student
		IF (EXISTS(select code from limitedcourses, registered 
			where code = NEW.course group by code having count(*) < limitedcourses.capacity))
-- Add student as registered in the limited course
			THEN INSERT INTO Registered VALUES (NEW.student, NEW.course);
		ELSE
-- Add student to the waitinglist of the limited course
			INSERT INTO Waitinglist VALUES (NEW.student, NEW.course, COALESCE((SELECT COUNT(*)+1 FROM Waitinglist WHERE NEW.course = course GROUP BY course) , 1));
		END IF;
		
-- If the course has no limitation, then just add the student to the course
	ELSE
		INSERT INTO Registered VALUES (NEW.student, NEW.course);

	END IF;
	
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_insert INSTEAD OF INSERT ON Registrations
    FOR  EACH  ROW
    EXECUTE PROCEDURE trigger_insert();
	
----
----
----
----
----
----

CREATE or replace FUNCTION trigger_delete() RETURNS trigger as $$
BEGIN

--Check if student exists and course exists
	IF (NOT EXISTS(SELECT idnr FROM Students where NEW.student = idnr) OR 
	   (NOT EXISTS(SELECT code FROM courses where NEW.course = code)))
		THEN RAISE EXCEPTION 'Student is not a student or course is not a course';
	END IF;
	
--Check if student is already registered or in waitinglist
    IF (NOT EXISTS (SELECT student, course FROM Registrations WHERE student = NEW.student and course = NEW.course) )
        THEN RAISE EXCEPTION 'Student is not registered or in waitinglist';
    END IF;
	
-- Check whether course is limited
	IF (NOT EXISTS (SELECT * FROM LimitedCourses WHERE NEW.course = code))
		THEN DELETE FROM Registered WHERE Student = NEW.Student AND Course = NEW.course;
	END IF;
		
	
-- Check whether limited course has room for an additional student
	IF (EXISTS(select code from limitedcourses, registered
		where code = NEW.course GROUP BY code HAVING COUNT(*) <= limitedcourses.capacity) AND ( NOT EXISTS (SELECT * FROM Waitinglist WHERE New.course = course))
		THEN DELETE FROM Registered WHERE Student = NEW.Student AND Course = NEW.course;
	END IF;
	
-- Check if there are more registrations on the course than the capacity 
	IF (EXISTS(select code from limitedcourses, registrations 
		where code = NEW.course group by code having count(*) > limitedcourses.capacity))
		THEN 
-- If student is in the course then delete it AND insert the first student from the waitinglist, and update the queue number for all students waiting
		IF (EXISTS(select code from limitedcourses, registered where code = NEW.course))
			THEN 
			DELETE FROM registered WHERE Student = NEW.Student AND Course = NEW.course;
			INSERT INTO registered (student, course) SELECT (student, course) FROM Waitinglist 
			WHERE NEW.course = Waitinglist.course AND NEW.student = waitinglist.student AND waitinglist.position = 1;
			
			
		
		
	END IF;
	
	
	
-- Add student to the waitinglist of the limited course
		INSERT INTO Waitinglist VALUES (NEW.student, NEW.course, COALESCE((SELECT COUNT(*)+1 FROM Waitinglist WHERE NEW.course = course GROUP BY course) , 1));
	END IF;
	
-- If the course has no limitation, then just add the student to the course
	ELSE
		INSERT INTO Registered VALUES (NEW.student, NEW.course);

	END IF;
	
	RETURN NEW;
END
$$ LANGUAGE plpgsql;



CREATE TRIGGER trig_delete INSTEAD OF DELETE ON Registrations
    FOR  EACH  ROW
    EXECUTE PROCEDURE trigger_delete();

-- IF (NOT EXISTS (select student, Prerequisities.course, precourse from Prerequisities join passedcourses ON precourse = passedcourses.course WHERE student = NEW.student and Prerequisities.course = NEW.course))
   -- THEN 

/*

IF (NOT EXISTS(SELECT student FROM passedcourses, Prerequisities 
		WHERE Prerequisities.pcourse = passedcourses.course AND NEW.student = student))
	THEN RAISE EXCEPTION 'The student has read the prerequisite course/s';
	END IF;


CREATE  TRIGGER name { BEFORE | AFTER | INSTEAD OF } 
    ON table
    FOR  EACH  { ROW | STATEMENT }
    EXECUTE PROCEDURE function_name
*/
/*
AND(EXISTS (SELECT COUNT(student) FROM Registrations, limitedcourses where registered.course = Limitedcourse.code group by course)))
    */

    /*OR NOT EXISTS (SELECT student, course FROM waitinglist WHERE student = NEW.student and course = NEW.course)*/
--
