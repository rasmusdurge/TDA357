
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

--Mandatory courses from branch and program but remove passed courses
CREATE OR REPLACE VIEW UnreadMandatory AS (
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
	EXCEPT
	SELECT student, course FROM PassedCourses
	ORDER BY student
); 




-- All pointers
-- Union of students with zero credits and students with positive credits
 CREATE OR REPLACE VIEW AllPointers AS (
	SELECT Students.idnr as student, 0 as TotalCredits
	FROM Students, PassedCourses
	WHERE Students.idnr NOT IN (SELECT student FROM PassedCourses)
	group by idnr
	UNION 
	SELECT Students.idnr as student, sum(PassedCourses.credits) as TotalCredits
	FROM Students
	JOIN PassedCourses
	ON Students.idnr = PassedCourses.student
	GROUP BY Students.idnr
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
 
	CREATE OR REPLACE VIEW AllMathCredits AS (
	select student, sum(credits) as mathcredits from passedcourses 
	join classified on passedcourses.course = classified.course 
	where classification = 'math' group by student 
	union 
	select idnr, 0 from students 
	except
	select student, 0 from passedcourses
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
	-- All students with a passed seminar course union all students with no such course
 CREATE OR REPLACE VIEW AllPassedSeminar AS ( 
	SELECT student, 1 as passedseminar
	FROM PassedCourses
	JOIN Classified
	ON PassedCourses.course = Classified.course
	WHERE classification = 'seminar'
	GROUP BY student
	UNION ALL
	SELECT DISTINCT BasicInformation.idnr as student, 0 as passedseminar
	FROM BasicInformation
	WHERE BasicInformation.idnr NOT IN (SELECT student FROM PassedCourses, Classified
	WHERE PassedCourses.course = Classified.course
	AND classification = 'seminar')
	ORDER BY student
	);
 
 CREATE OR REPLACE VIEW UnreadRecommendedHelper AS (
 
	SELECT idnr as student, SUM(credits) as recommendedCredits FROM BasicInformation, PassedCourses, RecommendedBranch
	WHERE 
		RecommendedBranch.course = PassedCourses.course AND
		BasicInformation.program = RecommendedBranch.program AND
		BasicInformation.branch = RecommendedBranch.branch AND
		BasicInformation.idnr = PassedCourses.student
	GROUP BY idnr
	
	);
 CREATE OR REPLACE VIEW UnreadRecommended AS (
	SELECT * FROM UnreadRecommendedHelper 
	UNION
	SELECT idnr as student, '0' as recommendedCredits FROM BasicInformation
	EXCEPT 
	SELECT student, '0' as recommendedCredits FROM UnreadRecommendedHelper
	ORDER BY student
	);
 

-- The collected view that show the remaining path to graduation
CREATE OR REPLACE VIEW PathToGraduationHelper AS (

	SELECT AllPointers.student as student, totalCredits, MandatoryLeft, 
		mathcredits, researchcredits, passedseminar, recommendedCredits FROM AllPointers
	JOIN MandatoryLeft
	ON AllPointers.student = MandatoryLeft.student
	JOIN AllMathCredits
	ON AllMathCredits.student = AllPointers.student
	JOIN AllResearchCredits
	ON AllResearchCredits.student = AllPointers.student
	/*JOIN QualifiedRecommendedCourses
	ON AllPointers.student = QualifiedRecommendedCourses.student
	*/
	JOIN AllPassedSeminar
	ON AllPassedSeminar.student = AllPointers.student
	JOIN UnreadRecommended
	ON UnreadRecommended.student = AllPointers.student
	
);


-- The collected view that show the remaining path to graduation
CREATE OR REPLACE VIEW PathToGraduation AS (

--student, totalCredits, mandatoryLeft,
-- mathCredits, researchCredits, seminarCourses, qualified
	SELECT student, totalCredits, mandatoryleft as mandatoryLeft, 
		mathcredits as mathCredits, researchcredits as researchCredits,
		passedseminar as seminarCourses, MandatoryLeft = 0 AND mathcredits >= 20 AND researchcredits >= 10
		AND passedseminar > 0 AND recommendedCredits >= 10 AS qualified
	FROM PathToGraduationHelper
);
 
