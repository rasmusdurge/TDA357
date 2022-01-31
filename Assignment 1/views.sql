
-- View of BasicInformation 
CREATE OR REPLACE VIEW BasicInformation AS (
	SELECT idnr, Students.name, login, Students.program, Studentbranches.branch AS branch
	FROM Students LEFT OUTER JOIN StudentBranches ON Students.idnr = StudentBranches.student
	);
	
-- View of FinishedCourses  	
CREATE OR REPLACE VIEW FinishedCourses AS (
	SELECT student, Taken.course as course, grade, Courses.credits AS credits
	FROM Taken LEFT OUTER JOIN Courses ON Courses.code = Taken.course
	ORDER BY array_position(ARRAY['U','3','4','5']::CHAR[],grade) desc,student, course
	
	);
	
-- View of PassedCourses
CREATE OR REPLACE VIEW PassedCourses AS (
	SELECT student, Taken.course as course, Courses.credits AS credits
	FROM Taken LEFT OUTER JOIN Courses ON Courses.code = Taken.course
	WHERE grade NOT IN ('U')
	ORDER BY student asc, course asc
	);
	
-- View of Registrations
CREATE OR REPLACE VIEW Registrations as (
	SELECT student, course, 'registered' as status FROM Registered
	UNION 
	SELECT student, course, 'waiting' as status FROM WaitingList
	);

--Helper view to create the unread mandatory courses	
CREATE OR REPLACE VIEW UnreadMandatoryHelper as (
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
	
-- View of unread mandatory courses
CREATE OR REPLACE VIEW UnreadMandatory AS (
	SELECT * FROM UnreadMandatoryHelper
	EXCEPT
	SELECT student, course FROM PassedCourses
	ORDER BY student

); 

-- All pointers

--Helper view to create total credits 
--This view selects all student that have zero total credits
CREATE OR REPLACE VIEW ZeroPointers AS (
	SELECT Students.idnr as student, 0 as TotalCredits
	FROM Students, PassedCourses
	WHERE Students.idnr NOT IN (SELECT student FROM PassedCourses)
	--REPLACE BY PassedCourses.students ? 
	
	GROUP BY idnr
	);
-- This helper table selects student that have >0 total credits
 CREATE OR REPLACE VIEW Pointers AS (
	SELECT Students.idnr as student, sum(PassedCourses.credits) as TotalCredits
	FROM Students
	JOIN PassedCourses
	ON Students.idnr = PassedCourses.student
	GROUP BY Students.idnr
	ORDER BY Students.idnr asc
	);

-- This view creates the union of the two previous views to see all students
-- and their corresponding total credits
 CREATE OR REPLACE VIEW AllPointers AS (
 SELECT * FROM Pointers
 UNION 
 SELECT * FROM ZeroPointers
 ORDER BY student
 
 );
 
 -- This view corresponds each student with the number of remaining mandatory courses
 CREATE OR REPLACE VIEW MandatoryLeft AS (
	SELECT student as student, count(UnreadMandatory.student) as MandatoryLeft
	FROM UnreadMandatory
	--REPLACE BY PassedCourses.students ? 
	GROUP BY student
	UNION ALL
	SELECT Students.idnr as student, '0' as MandatoryLeft 
	FROM Students
	WHERE Students.idnr NOT IN (SELECT UnreadMandatory.student FROM UnreadMandatory)
	GROUP BY student
 
 );
 
 -- Total amount of math credits
 
 -- Helper view for all students with positive math credits
 CREATE OR REPLACE VIEW PositiveMathCredits AS (
	SELECT student as student, SUM(credits) as mathcredits
	FROM PassedCourses
	JOIN Classified
	ON PassedCourses.course = Classified.course
	WHERE classification = 'math'
	GROUP BY student
 );
 
 -- Helper view for all students with zero math credits
 CREATE OR REPLACE VIEW ZeroMathCredits AS ( 
	SELECT DISTINCT BasicInformation.idnr as student, '0' as mathcredits
	FROM BasicInformation, PositiveMathCredits
	WHERE BasicInformation.idnr NOT IN (SELECT student FROM PositiveMathCredits)
	
 );
 
 -- All students and their corresponding number of math credits
 CREATE OR REPLACE VIEW AllMathCredits AS ( 
	SELECT PositiveMathCredits.student, mathcredits FROM PositiveMathCredits
	UNION 
	SELECT ZeroMathCredits.student as student, '0' FROM ZeroMathCredits
	);
 
 -- Total number of research credits 
 CREATE OR REPLACE VIEW PositiveResearchCredits AS (
	SELECT student as student, SUM(credits) as researchcredits
	FROM PassedCourses
	JOIN Classified
	ON PassedCourses.course = Classified.course
	WHERE classification = 'research'
	GROUP BY student
 );
 
 -- Helper view for all students with zero research credits
 CREATE OR REPLACE VIEW ZeroResearchCredits AS ( 
	SELECT DISTINCT BasicInformation.idnr as student, '0' as researchcredits
	FROM BasicInformation, PositiveResearchCredits
	WHERE BasicInformation.idnr NOT IN (SELECT student FROM PositiveResearchCredits)
 );
 
 -- Helper view for all students with positve research credits
 CREATE OR REPLACE VIEW AllResearchCredits AS ( 
	SELECT PositiveResearchCredits.student, researchcredits FROM PositiveResearchCredits
	UNION 
	SELECT ZeroResearchCredits.student as student, '0' FROM ZeroResearchCredits
	);
	
	--SEMINAR 
	
 -- Helper view for all students with 1 or more seminar courses
 CREATE OR REPLACE VIEW PassedSeminar AS (
	SELECT student, 1 as passedseminar
	FROM PassedCourses
	JOIN Classified
	ON PassedCourses.course = Classified.course
	WHERE classification = 'seminar'
	GROUP BY student
 );
 
 -- Helper view for all students with no seminar course
 CREATE OR REPLACE VIEW NotPassedSeminar AS ( 
	SELECT DISTINCT BasicInformation.idnr as student, 0 as passedseminar
	FROM BasicInformation, PassedSeminar
	WHERE BasicInformation.idnr NOT IN (SELECT student FROM PassedSeminar)
 );
 
 -- All students with or without seminar courses
 CREATE OR REPLACE VIEW AllPassedSeminar AS ( 
	SELECT PassedSeminar.student, PassedSeminar.passedseminar FROM PassedSeminar
	UNION ALL
	SELECT NotPassedSeminar.student as student, NotPassedSeminar.passedseminar FROM NotPassedSeminar
	ORDER BY student
	);
-- END SEMINAR

 
 -- Recommended course
 /*
  CREATE OR REPLACE VIEW UnreadRecommendedHelper as (
  
	SELECT idnr as student, 'hej' as course
	FROM BasicInformation
	EXCEPT 
	SELECT student, 'hej' as course from s
	
	);
	CREATE OR REPLACE VIEW s as (
	
	SELECT idnr as student, course FROM BasicInformation, RecommendedBranch
	WHERE BasicInformation.branch = RecommendedBranch.branch AND 
	BasicInformation.program = RecommendedBranch.program
	EXCEPT 
	SELECT student, course FROM PassedCourses
	GROUP BY student, course
	HAVING sum(PassedCourses.credits) >= 10 
	ORDER BY student
	);
-- View of unread recommended courses
CREATE OR REPLACE VIEW UnreadRecommended AS (
	SELECT student,course as course FROM UnreadRecommendedHelper
	EXCEPT
	SELECT student, course FROM PassedCourses
	GROUP BY student, course
	HAVING sum(PassedCourses.credits) >= 10 
	ORDER BY student
); */
 
 
 CREATE OR REPLACE VIEW UnreadRecommendedHelper as (
	SELECT idnr as student, RecommendedBranch.course as course
	FROM BasicInformation
	JOIN RecommendedBranch
	ON BasicInformation.branch = RecommendedBranch.branch AND 
	BasicInformation.program = RecommendedBranch.program
	UNION
	SELECT idnr as student, 'No course yet' as course FROM BasicInformation
	WHERE BasicInformation.branch IS NULL
	
	);
	
-- View of unread recommended courses
CREATE OR REPLACE VIEW UnreadRecommended AS (
	SELECT student,course as course FROM UnreadRecommendedHelper
	EXCEPT
	SELECT student, course FROM PassedCourses
	GROUP BY student, course
	HAVING sum(PassedCourses.credits) >= 10 
	ORDER BY student
); 


CREATE OR REPLACE VIEW QualifiedRecommendedCourses AS (

	SELECT Students.idnr as student, ABS(SUM(case when
		UnreadRecommended.student IN (Students.idnr) then 1 else 0 end)-1) as qualified
	FROM Students, UnreadRecommended
	GROUP BY idnr
	);
	


-- The collected view that show the remaining path to graduation
CREATE OR REPLACE VIEW PathToGraduationHelper AS (

	SELECT AllPointers.student as student, totalCredits, MandatoryLeft, 
		mathcredits, researchcredits, qualified, passedseminar FROM AllPointers
	JOIN MandatoryLeft
	ON AllPointers.student = MandatoryLeft.student
	JOIN AllMathCredits
	ON AllMathCredits.student = AllPointers.student
	JOIN AllResearchCredits
	ON AllResearchCredits.student = AllPointers.student
	JOIN QualifiedRecommendedCourses
	ON AllPointers.student = QualifiedRecommendedCourses.student
	JOIN AllPassedSeminar
	ON AllPassedSeminar.student = AllPointers.student
	
);


-- The collected view that show the remaining path to graduation
CREATE OR REPLACE VIEW PathToGraduation AS (

--student, totalCredits, mandatoryLeft,
-- mathCredits, researchCredits, seminarCourses, qualified
	SELECT student, totalCredits, mandatoryleft as mandatoryLeft, 
		mathcredits as mathCredits, researchcredits as researchCredits, passedseminar as seminarCourses,
		
	CASE
		WHEN MandatoryLeft = 0 AND mathcredits >= 20 AND researchcredits >= 10
		AND passedseminar > 0 AND qualified = 1 THEN TRUE
		ELSE FALSE
				
	END AS qualified
	FROM PathToGraduationHelper
);
 
