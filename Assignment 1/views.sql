
CREATE VIEW BasicInformation AS (
	SELECT student_id, Students.name, login, Students.program, Branches.name as branch
	FROM Students, Branches
	);
	
	
CREATE VIEW test AS (
	SELECT * FROM Students
	);
	

	
	
	