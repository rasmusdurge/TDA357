
-- students (('1111111111','N1','ls1','Prog1');

CREATE TABLE Students (
    student_id INT NOT NULL PRIMARY KEY UNIQUE CHECK (LEN(CONVERT(CHAR,student_id)) == 10,
    name CHAR(255) NOT NULL,
    login CHAR(255)NOT NULL,
	program CHAR(255) NOT NULL
   ....
);

CREATE TABLE Branches ( 
	name CHAR(255) NOT NULL,
	program CHAR(255) NOT NULL
	PRIMARY KEY(name, program)
);
	
CREATE TABLE Courses (
	code CHAR(6) NOT NULL PRIMARY KEY,
	name CHAR(255) NOT NULL,
	credits FLOAT NOT NULL,
	department CHAR(255) NOT FULL
);

CREATE TABLE LimitedCourses (
	
	code CHAR(6) PRIMARY KEY FOREIGN KEY REFERENCES Courses, 
	capacity INT check (capacity > 0),

)

CREATE TABLE StudentBranches (
	name CHAR(255) NOT NULL,
	program CHAR(255) NOT NULL,
	student int
	FOREIGN KEY (student) REFERENCES Students(student_id),
	
	FOREIGN KEY (name, program) REFERENCES Branches
	
	REFERENCES Students.student_id


)
