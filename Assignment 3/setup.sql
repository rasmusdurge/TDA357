--SETUP



CREATE TABLE Department (
	name TEXT PRIMARY KEY NOT NULL,
	abbr TEXT UNIQUE NOT NULL
);

CREATE TABLE Program ( 
	name CHAR(5) NOT NULL PRIMARY KEY,
	abbr TEXT NOT NULL
	--department TEXT NOT NULL,
	--FOREIGN KEY (department) REFERENCES Department(name)
);

CREATE TABLE Students (
    idnr CHAR(10) NOT NULL PRIMARY KEY CHECK (idnr SIMILAR TO '[0-9]{10}'),
	name TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
	program CHAR(5) NOT NULL,
	FOREIGN KEY (program) REFERENCES Program(name),
	UNIQUE (idnr, program)
);

CREATE TABLE progToDepartment(
	depName TEXT NOT NULL,
	progName TEXT NOT NULL,
	FOREIGN KEY (depName) REFERENCES Department(name),
	FOREIGN KEY (progName) REFERENCES Program(name),
	PRIMARY KEY (depName, progName)
);

CREATE TABLE Branches ( 
	name TEXT NOT NULL,
	program TEXT NOT NULL,
	FOREIGN KEY (program) REFERENCES program(name),
	PRIMARY KEY(name, program)
);
	
CREATE TABLE Courses (
	code CHAR(6) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	credits FLOAT NOT NULL CHECK(credits >= 0),
	department TEXT NOT NULL,
	FOREIGN KEY (department) REFERENCES department(name)

);

CREATE TABLE Prerequisities(
    course CHAR(6),
    pCourse CHAR(6),
    FOREIGN KEY (course) REFERENCES Courses(code),
	FOREIGN KEY (pCourse) REFERENCES Courses(code)
);

CREATE TABLE LimitedCourses (
	code CHAR(6) NOT NULL,
	PRIMARY KEY(code),
	FOREIGN KEY (code) REFERENCES Courses, 
	capacity INT check (capacity > 0) NOT NULL
);

CREATE TABLE StudentBranches (
	student CHAR(10) NOT NULL PRIMARY KEY CHECK (student SIMILAR TO '[0-9]{10}'),
	branch TEXT NOT NULL,
	program TEXT NOT NULL,
	FOREIGN KEY (student, program) REFERENCES Students(idnr, program),
	FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Classifications(
	name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE Classified(
	course CHAR(6) NOT NULL,
	classification TEXT NOT NULL,
	
	FOREIGN KEY (course) REFERENCES Courses,
	FOREIGN KEY (classification) REFERENCES Classifications,
	PRIMARY KEY(course,classification)
);

CREATE TABLE MandatoryProgram(
	course CHAR(6) NOT NULL,
	program TEXT NOT NULL,
	FOREIGN KEY (course) REFERENCES Courses(code),
	PRIMARY KEY (course, program) 
);

CREATE TABLE MandatoryBranch(
	course CHAR(6) NOT NULL,
	branch TEXT,
	program TEXT NOT NULL,
	
	FOREIGN KEY (course) REFERENCES Courses,
	FOREIGN KEY (branch, program) REFERENCES Branches,
	PRIMARY KEY (course,branch,program)
);

CREATE TABLE RecommendedBranch(
	course CHAR(6) NOT NULL,
	branch TEXT,
	program TEXT NOT NULL,
	FOREIGN KEY (course) REFERENCES Courses,
	FOREIGN KEY (branch, program) REFERENCES Branches,
	PRIMARY KEY (course,branch,program)
);
	
CREATE TABLE Registered(
	student CHAR(10) NOT NULL,
	course CHAR(6) NOT NULL,
	FOREIGN KEY (student) REFERENCES Students ON DELETE CASCADE,
	FOREIGN KEY (course) REFERENCES Courses ON DELETE CASCADE,
	PRIMARY KEY (student, course)
);

CREATE TABLE Taken(
	student CHAR(10),
	course CHAR(6) NOT NULL,
	grade CHAR(1) NOT NULL,
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (course) REFERENCES Courses,
	PRIMARY KEY (student, course),
	CONSTRAINT okgrade CHECK (grade IN ('U','3','4','5'))
);

CREATE TABLE WaitingList(
	student CHAR(10),
	course CHAR(6) NOT NULL,
	position SERIAL NOT NULL,
	FOREIGN KEY (student) REFERENCES Students ON DELETE CASCADE,
	FOREIGN KEY (course) REFERENCES LimitedCourses ON DELETE CASCADE,
	PRIMARY KEY (student,course),
	UNIQUE (position, course)
	);
	
	
---------------------------------------------
--VIEWS



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

create or replace view CourseQueuePositions as(
    select course, student, position as place from waitinglist
);

 
---------------------------------------------------------------
--INSERTS

INSERT INTO Department VALUES ('Dep1','D1');

--INSERT INTO Prerequisities VALUES ('CCC222','');

INSERT INTO Program VALUES ('Prog1','p1');
INSERT INTO Program VALUES ('Prog2','p2');

INSERT INTO progToDepartment VALUES ('Dep1', 'Prog1');
INSERT INTO progToDepartment VALUES ('Dep1', 'Prog2');

INSERT INTO Branches VALUES ('B1','Prog1');
INSERT INTO Branches VALUES ('B2','Prog1');
INSERT INTO Branches VALUES ('B1','Prog2');

INSERT INTO Students VALUES ('1111111111','N1','ls1','Prog1');
INSERT INTO Students VALUES ('2222222222','N2','ls2','Prog1');
INSERT INTO Students VALUES ('3333333333','N3','ls3','Prog2');
INSERT INTO Students VALUES ('4444444444','N4','ls4','Prog1');
INSERT INTO Students VALUES ('5555555555','Nx','ls5','Prog2');
INSERT INTO Students VALUES ('6666666666','Nx','ls6','Prog2');

INSERT INTO Courses VALUES ('CCC111','C1',22.5,'Dep1');
INSERT INTO Courses VALUES ('CCC222','C2',20,'Dep1');
INSERT INTO Courses VALUES ('CCC333','C3',30,'Dep1');
INSERT INTO Courses VALUES ('CCC444','C4',60,'Dep1');
INSERT INTO Courses VALUES ('CCC555','C5',50,'Dep1');

INSERT INTO LimitedCourses VALUES ('CCC222',1);
INSERT INTO LimitedCourses VALUES ('CCC333',2);


INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');

INSERT INTO StudentBranches VALUES ('2222222222','B1','Prog1');
INSERT INTO StudentBranches VALUES ('3333333333','B1','Prog2');
INSERT INTO StudentBranches VALUES ('4444444444','B1','Prog1');
INSERT INTO StudentBranches VALUES ('5555555555','B1','Prog2');

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC444', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B1', 'Prog2');

INSERT INTO Registered VALUES ('1111111111','CCC111');
INSERT INTO Registered VALUES ('1111111111','CCC222');
INSERT INTO Registered VALUES ('1111111111','CCC333');
INSERT INTO Registered VALUES ('2222222222','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC333');

INSERT INTO Taken VALUES('4444444444','CCC111','5');
INSERT INTO Taken VALUES('4444444444','CCC222','5');
INSERT INTO Taken VALUES('4444444444','CCC333','5');
INSERT INTO Taken VALUES('4444444444','CCC444','5');

INSERT INTO Taken VALUES('5555555555','CCC111','5');
INSERT INTO Taken VALUES('5555555555','CCC222','4');
INSERT INTO Taken VALUES('5555555555','CCC444','3');

INSERT INTO Taken VALUES('2222222222','CCC111','U');
INSERT INTO Taken VALUES('2222222222','CCC222','U');
INSERT INTO Taken VALUES('2222222222','CCC444','U');

INSERT INTO WaitingList VALUES('3333333333','CCC222',1);
INSERT INTO WaitingList VALUES('3333333333','CCC333',1);
INSERT INTO WaitingList VALUES('2222222222','CCC333',2);



