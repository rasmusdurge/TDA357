
-- students (('1111111111','N1','ls1','Prog1');

CREATE TABLE Students (
    student_id BIGINT NOT NULL PRIMARY KEY UNIQUE CHECK (1000000000 <= student_id AND student_id <= 10000000000),
    name CHAR(255) NOT NULL,
    login CHAR(255)NOT NULL,
	program CHAR(255) NOT NULL
);

CREATE TABLE Branches ( 
	name CHAR(254) NOT NULL,
	program CHAR(255) NOT NULL,
	PRIMARY KEY(name, program)
);
	
CREATE TABLE Courses (
	code CHAR(6) NOT NULL PRIMARY KEY,
	name CHAR(255) NOT NULL,
	credits FLOAT NOT NULL,
	department CHAR(255) NOT NULL
);

CREATE TABLE LimitedCourses (
	code CHAR(6),
	PRIMARY KEY(code),
	FOREIGN KEY (code) REFERENCES Courses, 
	capacity INT check (capacity > 0)
);

CREATE TABLE StudentBranches (
	name CHAR(255) NOT NULL,
	program CHAR(255) NOT NULL,
	student BIGINT,
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (name, program) REFERENCES Branches
);

CREATE TABLE Classifications(
	name CHAR(255) NOT NULL PRIMARY KEY
);

CREATE TABLE Classified(
	course CHAR(6) NOT NULL,
	classification CHAR(255) NOT NULL,
	
	FOREIGN KEY (course) REFERENCES Courses,
	FOREIGN KEY (classification) REFERENCES Classifications,
	PRIMARY KEY(course,classification)
);

CREATE TABLE MandatoryProgram(
	course CHAR(6) NOT NULL,
	program CHAR(255) NOT NULL,
	
	FOREIGN KEY (course) REFERENCES Courses
);

CREATE TABLE MandatoryBranch(
	course CHAR(6) NOT NULL,
	branch CHAR(255),
	program CHAR(255) NOT NULL,
	
	FOREIGN KEY (course) REFERENCES Courses,
	FOREIGN KEY (branch, program) REFERENCES Branches,
	PRIMARY KEY (course,branch,program)
);

CREATE TABLE RecommendedBranch(
	course CHAR(6) NOT NULL,
	branch CHAR(255),
	program CHAR(255) NOT NULL,

	FOREIGN KEY (course) REFERENCES Courses,
	FOREIGN KEY (branch, program) REFERENCES Branches,
	PRIMARY KEY (course,branch,program)
);
	 
CREATE TABLE Registered(
	student BIGINT NOT NULL,
	course CHAR(255) NOT NULL,
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (course) REFERENCES Courses,
	PRIMARY KEY (student, course)
);

CREATE TABLE Taken(
	student BIGINT NOT NULL,
	course CHAR(255) NOT NULL,
	grade CHAR(1),
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (course) REFERENCES Courses,
	PRIMARY KEY (student, course)
);

CREATE TABLE WaitingList(
	student BIGINT NOT NULL,
	course CHAR(255) NOT NULL,
	position SERIAL NOT NULL,
	FOREIGN KEY (student) REFERENCES Students,
	FOREIGN KEY (course) REFERENCES LimitedCourses,
	PRIMARY KEY (student,course)
	);
	
