
CREATE TABLE Students (
    idnr CHAR(10) NOT NULL PRIMARY KEY CHECK (idnr SIMILAR TO '[0-9]{10}'),
	name TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
	program TEXT NOT NULL,
	UNIQUE (idnr, program)
);

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
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (course) REFERENCES Courses,
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
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (course) REFERENCES LimitedCourses,
	PRIMARY KEY (student,course),
	UNIQUE (student, course)
	);
	
	
