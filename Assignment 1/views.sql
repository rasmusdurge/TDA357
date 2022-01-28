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
	--ORDER BY array_position(ARRAY['U','3','4','5']::VARCHAR[],grade) desc,student, course
	);
	
CREATE VIEW PassedCourses AS (
	SELECT student, Taken.course as course, Courses.credits AS credits
	FROM Taken LEFT OUTER JOIN Courses ON Courses.code = Taken.course
	WHERE grade NOT IN ('U')
	--ORDER BY array_position(ARRAY['5','4','3']::VARCHAR[],grade),student, course
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
	ORDER BY student

); 
CREATE VIEW ZeroPointers AS (
	SELECT Students.idnr as student, 0 as TotalCredits
	FROM Students, PassedCourses
	WHERE Students.idnr NOT IN ('4444444444','5555555555')
	--REPLACE BY PassedCourses.students ? 
	
	GROUP BY idnr
	);

 CREATE VIEW Pointers AS (
	SELECT Students.idnr as student, sum(PassedCourses.credits) as TotalCredits
	FROM Students
	JOIN PassedCourses
	ON Students.idnr = PassedCourses.student
	GROUP BY Students.idnr
	ORDER BY Students.idnr asc
	);
		
 CREATE VIEW PathToGraduation AS (
 SELECT * FROM Pointers
 UNION 
 SELECT * FROM ZeroPointers
 ORDER BY student
 
 
 --RIGHT JOIN MandatoryLeft ON student = MandatoryLeft.student

 /*
 UNION 
 SELECT * FROM mandatoryLeft
 ORDER BY student*/
 
 );
 
 
 CREATE VIEW MandatoryLeft AS (
	SELECT student as student, count(UnreadMandatory.student) as MandatoryLeft
	FROM UnreadMandatory
	--REPLACE BY PassedCourses.students ? 
	GROUP BY student
	UNION ALL
	SELECT Students.idnr as student, '0' as MandatoryLeft 
	FROM Students
	WHERE Students.idnr NOT IN ('1111111111','2222222222','3333333333')
	GROUP BY student
 
 );

 );
 