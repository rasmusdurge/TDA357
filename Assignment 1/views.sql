/*
CREATE VIEW BasicInformation AS (
	SELECT idnr, Students.name, login, Students.program, Studentbranches.name as branch
	FROM Students, StudentBranches
	WHERE Students.idnr = StudentBranches.student
	);
*/
	
CREATE VIEW BasicInformation AS (
	SELECT idnr, Students.name, login, Students.program, Studentbranches.name AS branch
	FROM Students LEFT OUTER JOIN StudentBranches ON Students.idnr = StudentBranches.student
	);
	
CREATE VIEW FinishedCourses AS (
	SELECT student, Taken.course as course, grade, Courses.credits AS credits
	FROM Taken LEFT OUTER JOIN Courses ON Courses.code = Taken.course
	ORDER BY array_position(ARRAY['U','3','4','5']::VARCHAR[],grade) desc,student, course
	);
	
CREATE VIEW PassedCourses AS (
	SELECT student, Taken.course as course, Courses.credits AS credits
	FROM Taken LEFT OUTER JOIN Courses ON Courses.code = Taken.course
	WHERE grade NOT IN ('U')
	ORDER BY array_position(ARRAY['3','4','5']::VARCHAR[],grade) desc,student, course
	);
	
CREATE VIEW Registrations as (
	SELECT student, course, 'registered' as status FROM Registered
	UNION 
	SELECT student, course, 'waiting' as status FROM WaitingList
	);
	
CREATE VIEW UnreadMandatoryHelper as (
	SELECT idnr as student, MandatoryBranch.course
	FROM BasicInformation
	JOIN MandatoryBranch
	ON BasicInformation.branch = MandatoryBranch.branch AND 
	BasicInformation.program = MandatoryBranch.program
	UNION  
	SELECT idnr as student, MandatoryProgram.course
	FROM BasicInformation
	JOIN MandatoryProgram
	ON BasicInformation.program = MandatoryProgram.program 
	ORDER BY student 
	);
	
CREATE VIEW UnreadMandatory AS (
	SELECT * FROM UnreadMandatoryHelper
	EXCEPT
	SELECT student, course FROM PassedCourses
	
	--EXCEPT
	--SELECT student, course FROM Registrations

	--WHERE Registrations.status = 'registered'

	ORDER BY student

); 
 