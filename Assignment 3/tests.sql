
\ir triggers.sql 

/*

1. registered to an unlimited course;

2. registered to a limited course;

3. waiting for a limited course;

4. removed from a waiting list (with additional students in it)

5. unregistered from an unlimited course;

6. unregistered from a limited course without a waiting list;

7. unregistered from a limited course with a waiting list, when the student is registered;

8. unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;

9. unregistered from an overfull course with a waiting list.
*/
--INSERT INTO Prerequisities VALUES('CCC555', 'CCC444');

-- Limited courses CCC222, CCC333
-- Unlimited courses CCC111, CCC444, CCC555

/*
-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('XXXXXXXXXX', 'CCCXXX'); 

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('XXXXXXXXXX', 'CCCXXX'); 

-- TEST #3: Unregister from an unlimited course. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = 'XXXXXXXXXX' AND course = 'CCCXXX';
*/

-- Test 1. registered to an unlimited course
	-- EXPECTED OUTCOME: Pass
	INSERT INTO Registrations VALUES ('6666666666','CCC111');
	
	-- EXPECTED OUTCOME: Fail, student is already registered or in waitinglist
	INSERT INTO Registrations VALUES ('6666666666','CCC111');
	
	-- EXPECTED OUTCOME: Fail, not a student
	INSERT INTO Registrations VALUES ('7777777777','CCC555');
	
	-- EXPECTED OUTCOME: Fail, not a course
	INSERT INTO Registrations VALUES ('6666666666','CCC525');
	
	-- EXPECTED OUTCOME: Fail, student has already passed the course
	INSERT INTO Registrations VALUES ('5555555555','CCC222');
	
	--Test for prerequisities
		INSERT INTO Prerequisities VALUES ('CCC555', 'CCC222');
		
		-- EXPECTED OUTCOME: Pass
		INSERT INTO Registrations VALUES ('5555555555','CCC555');
		
		-- EXPECTED OUTCOME: Fail, student has not passed prerequisite course ('CCC222')
		INSERT INTO Registrations VALUES ('1111111111','CCC555');
	
-- Test 2. registered to a limited course
-- EXPECTED OUTCOME: Pass
	INSERT INTO Registrations VALUES ('1111111111','CCC333');

-- EXPECTED OUTCOME: Fail, not capacity enough
	INSERT INTO Registrations VALUES ('6666666666','CCC333');