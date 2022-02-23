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
	
	IF (EXISTS (SELECT * FROM passedcourses WHERE NEW.student = student AND NEW.course = course))
		THEN RAISE EXCEPTION 'Student has already passed this course';
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

		
-- Check if course has room for an additional student

	--split
		IF (NOT EXISTS (SELECT * FROM Registered WHERE course = NEW.course))
					THEN INSERT INTO Registered VALUES (NEW.student, NEW.course);
		ELSIF(EXISTS(select code from limitedcourses, registered 
			where code = NEW.course group by code having count(*) < limitedcourses.capacity))
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
DECLARE queuePos INTEGER;
		tempStudent  CHAR(10);
		tempCourse CHAR(6);
BEGIN 


--Check if student exists and course exists
	IF (NOT EXISTS(SELECT idnr FROM Students where OLD.student = idnr) OR 
	   (NOT EXISTS(SELECT code FROM courses where OLD.course = code)))
		THEN RAISE EXCEPTION 'Student is not a student or course is not a course';
	END IF;
	
--Check if student is not registered nor in waitinglist
    IF (NOT EXISTS (SELECT student, course FROM Registrations WHERE student = OLD.student AND course = OLD.course))
        THEN RAISE EXCEPTION 'Student is not registered or in waitinglist';
    END IF;
	
-- Check whether course is limited; If not, then just remove the student
	IF (NOT EXISTS (SELECT * FROM LimitedCourses WHERE OLD.course = code))
		THEN DELETE FROM Registered WHERE Student = OLD.Student AND Course = OLD.course;
	END IF;
	
-- Check whether course has a waitinglist; If not, just remove the student
	IF (NOT EXISTS (SELECT * FROM Waitinglist WHERE OLD.course = course))
		THEN DELETE FROM Registered WHERE Student = OLD.Student AND course = OLD.course;
		
	ELSE --Course has a waitinglist
	
		-- Is the student in the waitinglist?
		IF (EXISTS (SELECT * FROM Waitinglist WHERE OLD.course = course AND OLD.student = student))
			THEN
			queuePos = (SELECT position FROM Waitinglist WHERE OLD.student = student AND OLD.course = course);
			DELETE FROM Waitinglist WHERE OLD.Student = Student AND OLD.course = course;
		
			UPDATE Waitinglist
				SET 
					position = position - 1
				WHERE course = OLD.course AND position > (queuePos);
				
		
		ELSE -- Student is in registered and there is a waitinglist
		
				-- Are there too many registered students? Then just remove student
			IF (NOT EXISTS(select code from limitedcourses, registered where code = course group by code having count(student) > limitedcourses.capacity))
				THEN
				
				DELETE FROM Registered WHERE Student = OLD.Student AND course = OLD.course;
				
			ELSE
			-- Student is registered, and there is a waitinglist. We need to take the first student in the waitinglist and place in registered
				
				
				tempStudent = (SELECT student from Waitinglist WHERE course = OLD.course AND position = 1);
				tempCourse = (SELECT course from Waitinglist WHERE course = OLD.course AND position = 1);
				
				DELETE FROM Waitinglist WHERE tempCourse = course AND position = 1;
				
				DELETE FROM registered WHERE course = OLD.course AND student = OLD.student;
				
				INSERT INTO registered VALUES (tempStudent, tempCourse);				

				UPDATE Waitinglist
						SET 
							position = position - 1
						WHERE course = tempCourse;
			END IF;
			
		
		END IF;
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_delete INSTEAD OF DELETE ON Registrations
    FOR  EACH  ROW
    EXECUTE PROCEDURE trigger_delete();
	
--test