
CREATE TABLE Students (
    idnr CHAR(10) NOT NULL PRIMARY KEY CHECK (idnr SIMILAR TO '[0-9]{10}'),
	name TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
	program TEXT NOT NULL
);

CREATE TABLE Branches ( 
	name TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY(name, program)
);
	
CREATE TABLE Courses (
	code CHAR(6) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	credits FLOAT NOT NULL CHECK(credits >= 0),
	department TEXT NOT NULL
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
	FOREIGN KEY (student) REFERENCES Students(idnr),
	FOREIGN KEY (branch, program) REFERENCES Branches
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
	
	FOREIGN KEY (course) REFERENCES Courses,
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
	PRIMARY KEY (student,course)
	);
	
	
