-- HOSPITAL MANAGEMENT SYSTEM (Corrected)
-- Keeps your IDs/data the same; adds keys & set-based triggers; fixes final transaction.
-- Source: DBMS_project_final_rollno_06_04.sql  (user upload)

------------------------------------------------------------
-- Create & use database
------------------------------------------------------------
IF DB_ID('HMS1') IS NULL
    CREATE DATABASE HMS1;
GO
USE HMS1;
GO

------------------------------------------------------------
-- Drop objects if re-running (idempotent)
------------------------------------------------------------
-- NOTE: run once if you need a clean rebuild
IF OBJECT_ID('dbo.getAppointments') IS NOT NULL DROP PROCEDURE dbo.getAppointments;
IF OBJECT_ID('dbo.AddNewPatient')   IS NOT NULL DROP PROCEDURE dbo.AddNewPatient;
IF OBJECT_ID('dbo.UpdatePatientContact') IS NOT NULL DROP PROCEDURE dbo.UpdatePatientContact;
IF OBJECT_ID('dbo.GetDiseases')     IS NOT NULL DROP PROCEDURE dbo.GetDiseases;

IF OBJECT_ID('dbo.GetPatientAge')   IS NOT NULL DROP FUNCTION dbo.GetPatientAge;
IF OBJECT_ID('dbo.GetDoctorsInDepartment') IS NOT NULL DROP FUNCTION dbo.GetDoctorsInDepartment;

IF OBJECT_ID('dbo.UpdateDoctorJoiningDate','TR') IS NOT NULL DROP TRIGGER dbo.UpdateDoctorJoiningDate;
IF OBJECT_ID('dbo.AutoSetDischargeDate','TR')    IS NOT NULL DROP TRIGGER dbo.AutoSetDischargeDate;
GO

------------------------------------------------------------
-- Tables
------------------------------------------------------------
-- Tip: kept datatypes and nullability matching your file
--      and added PKs to junction tables to prevent duplicates.

IF OBJECT_ID('dbo.doctor') IS NOT NULL DROP TABLE dbo.doctor_contact_details;
IF OBJECT_ID('dbo.doctor_department') IS NOT NULL DROP TABLE dbo.doctor_department;
IF OBJECT_ID('dbo.doctor') IS NOT NULL DROP TABLE dbo.doctor;

CREATE TABLE doctor(
    DoctorID     INT CONSTRAINT HMSp1 PRIMARY KEY,
    FirstName    VARCHAR(40),
    LastName     VARCHAR(40),
    DOB          DATE,
    Gender       VARCHAR(20),
    JoiningDate  DATE
);
GO

CREATE TABLE doctor_contact_details(
    DoctorID    INT NOT NULL CONSTRAINT HMSf1 FOREIGN KEY REFERENCES doctor(DoctorID),
    PhoneNumber VARCHAR(20),
    EmailID     VARCHAR(90),
    CONSTRAINT PK_doctor_contact_details PRIMARY KEY (DoctorID) -- 1:1 contact info
);
GO

IF OBJECT_ID('dbo.department') IS NOT NULL DROP TABLE dbo.department;
CREATE TABLE department(
    DepartmentID   INT CONSTRAINT HMSp2 PRIMARY KEY,
    DepartmentName VARCHAR(50)
);
GO

IF OBJECT_ID('dbo.doctor_department') IS NOT NULL DROP TABLE dbo.doctor_department;
CREATE TABLE doctor_department(
    DoctorID    INT NOT NULL CONSTRAINT HMSf2 FOREIGN KEY REFERENCES doctor(DoctorID),
    DepartmentID INT NOT NULL CONSTRAINT HMSf3 FOREIGN KEY REFERENCES department(DepartmentID),
    CONSTRAINT PK_doctor_department PRIMARY KEY (DoctorID, DepartmentID)
);
GO

IF OBJECT_ID('dbo.addresses') IS NOT NULL DROP TABLE dbo.addresses;
CREATE TABLE addresses(
    AddressID INT CONSTRAINT HMSp3 PRIMARY KEY,
    Address1  VARCHAR(60),
    Address2  VARCHAR(60),
    City      VARCHAR(40),
    State     VARCHAR(40),
    Zipcode   INT  -- kept as INT to preserve your inserts
);
GO

IF OBJECT_ID('dbo.doctor_address') IS NOT NULL DROP TABLE dbo.doctor_address;
CREATE TABLE doctor_address(
    DoctorID  INT NOT NULL CONSTRAINT HMSf4 FOREIGN KEY REFERENCES doctor(DoctorID),
    AddressID INT NOT NULL CONSTRAINT HMSf5 FOREIGN KEY REFERENCES addresses(AddressID),
    CONSTRAINT PK_doctor_address PRIMARY KEY (DoctorID) -- assume 1:1 mapping in your data
);
GO

IF OBJECT_ID('dbo.patient_contact_details') IS NOT NULL DROP TABLE dbo.patient_contact_details;
IF OBJECT_ID('dbo.patient') IS NOT NULL DROP TABLE dbo.patient;

CREATE TABLE patient(
    PatientID  INT CONSTRAINT HMSp4 PRIMARY KEY,
    FirstName  VARCHAR(40),
    LastName   VARCHAR(40),
    DOB        DATE,
    Gender     VARCHAR(20),
    BloodGroup VARCHAR(20)
);
GO

CREATE TABLE patient_contact_details(
    PatientID    INT NOT NULL CONSTRAINT HMSf6 FOREIGN KEY REFERENCES patient(PatientID),
    PhoneNumber  VARCHAR(20),
    EmailID      VARCHAR(90),
    CONSTRAINT PK_patient_contact_details PRIMARY KEY (PatientID)
);
GO

IF OBJECT_ID('dbo.medical_test') IS NOT NULL DROP TABLE dbo.medical_test;
CREATE TABLE medical_test(
    TestID   INT CONSTRAINT HMSp5 PRIMARY KEY,
    TestName VARCHAR(50)
);
GO

IF OBJECT_ID('dbo.patient_test_report') IS NOT NULL DROP TABLE dbo.patient_test_report;
CREATE TABLE patient_test_report(
    PatientID INT NOT NULL CONSTRAINT HMSf7 FOREIGN KEY REFERENCES patient(PatientID),
    TestID    INT NOT NULL CONSTRAINT HMSf8 FOREIGN KEY REFERENCES medical_test(TestID),
    TestDate  DATE NULL,
    CONSTRAINT PK_patient_test_report PRIMARY KEY (PatientID, TestID)
);
GO

IF OBJECT_ID('dbo.procedure_1') IS NOT NULL DROP TABLE dbo.procedure_1;
CREATE TABLE procedure_1(
    ProcedureID   INT CONSTRAINT HMSp6 PRIMARY KEY,
    ProcedureName VARCHAR(80)
);
GO

IF OBJECT_ID('dbo.patient_prescription') IS NOT NULL DROP TABLE dbo.patient_prescription;
CREATE TABLE patient_prescription(
    PrescriptionID INT CONSTRAINT HMSp7 PRIMARY KEY,
    PatientID      INT NOT NULL CONSTRAINT HMSf9  FOREIGN KEY REFERENCES patient(PatientID),
    DoctorID       INT NOT NULL CONSTRAINT HMSf10 FOREIGN KEY REFERENCES doctor(DoctorID),
    PrescriptionDate DATE
);
GO

IF OBJECT_ID('dbo.patient_procedure') IS NOT NULL DROP TABLE dbo.patient_procedure;
CREATE TABLE patient_procedure(
    PrescriptionID INT NOT NULL CONSTRAINT HMSf11 FOREIGN KEY REFERENCES patient_prescription(PrescriptionID),
    WithDoctorID   INT NOT NULL CONSTRAINT HMSf12 FOREIGN KEY REFERENCES doctor(DoctorID),
    ProcedureID    INT NOT NULL CONSTRAINT HMSf13 FOREIGN KEY REFERENCES procedure_1(ProcedureID),
    ScheduledDate  DATE,
    PerformedDate  DATE NULL,
    CONSTRAINT PK_patient_procedure PRIMARY KEY (PrescriptionID, ProcedureID)
);
GO

IF OBJECT_ID('dbo.appointment') IS NOT NULL DROP TABLE dbo.appointment;
CREATE TABLE appointment(
    AppointmentID INT CONSTRAINT HMSp8 PRIMARY KEY,
    PatientID     INT NOT NULL CONSTRAINT HMSf14 FOREIGN KEY REFERENCES patient(PatientID),
    DoctorID      INT NOT NULL CONSTRAINT HMSf15 FOREIGN KEY REFERENCES doctor(DoctorID),
    ScheduledDate DATETIME
);
GO

IF OBJECT_ID('dbo.room') IS NOT NULL DROP TABLE dbo.room;
CREATE TABLE room(
    RoomID   INT CONSTRAINT HMSp9 PRIMARY KEY,
    RoomName VARCHAR(60)
);
GO

IF OBJECT_ID('dbo.patient_stay') IS NOT NULL DROP TABLE dbo.patient_stay;
CREATE TABLE patient_stay(
    PatientID    INT NOT NULL CONSTRAINT HMSf16 FOREIGN KEY REFERENCES patient(PatientID),
    RoomID       INT NOT NULL CONSTRAINT HMSf17 FOREIGN KEY REFERENCES room(RoomID),
    AdmitDate    DATE NOT NULL,
    DischargeDate DATE NULL,
    CONSTRAINT PK_patient_stay PRIMARY KEY (PatientID, AdmitDate)  -- unique stay per admit
);
GO

IF OBJECT_ID('dbo.disease') IS NOT NULL DROP TABLE dbo.disease;
CREATE TABLE disease(
    DiseaseID   INT CONSTRAINT HMSp10 PRIMARY KEY,
    DiseaseName VARCHAR(80)
);
GO

IF OBJECT_ID('dbo.patient_disease') IS NOT NULL DROP TABLE dbo.patient_disease;
CREATE TABLE patient_disease(
    PatientID INT NOT NULL CONSTRAINT HMSf18 FOREIGN KEY REFERENCES patient(PatientID),
    DiseaseID INT NOT NULL CONSTRAINT HMSf19 FOREIGN KEY REFERENCES disease(DiseaseID),
    Dated     DATE NOT NULL,
    CONSTRAINT PK_patient_disease PRIMARY KEY (PatientID, DiseaseID, Dated)
);
GO

IF OBJECT_ID('dbo.roles') IS NOT NULL DROP TABLE dbo.roles;
CREATE TABLE roles(
    RoleID   INT CONSTRAINT HMSp11 PRIMARY KEY,
    RoleName VARCHAR(80)
);
GO

IF OBJECT_ID('dbo.doctor_role') IS NOT NULL DROP TABLE dbo.doctor_role;
CREATE TABLE doctor_role(
    DoctorID INT NOT NULL CONSTRAINT HMSf20 FOREIGN KEY REFERENCES doctor(DoctorID),
    RoleID   INT NOT NULL CONSTRAINT HMSf21 FOREIGN KEY REFERENCES roles(RoleID),
    CONSTRAINT PK_doctor_role PRIMARY KEY (DoctorID, RoleID)
);
GO

IF OBJECT_ID('dbo.medicine') IS NOT NULL DROP TABLE dbo.medicine;
CREATE TABLE medicine(
    MedicineID   INT CONSTRAINT HMSp12 PRIMARY KEY,
    MedicineName VARCHAR(80)
);
GO

IF OBJECT_ID('dbo.patient_prescribed_medicines') IS NOT NULL DROP TABLE dbo.patient_prescribed_medicines;
CREATE TABLE patient_prescribed_medicines(
    PrescriptionID INT NOT NULL CONSTRAINT HMSf22 FOREIGN KEY REFERENCES patient_prescription(PrescriptionID),
    MedicineID     INT NOT NULL CONSTRAINT HMSf23 FOREIGN KEY REFERENCES medicine(MedicineID),
    CONSTRAINT PK_patient_prescribed_medicines PRIMARY KEY (PrescriptionID, MedicineID)
);
GO

IF OBJECT_ID('dbo.staff_contact_details') IS NOT NULL DROP TABLE dbo.staff_contact_details;
IF OBJECT_ID('dbo.staff_department') IS NOT NULL DROP TABLE dbo.staff_department;
IF OBJECT_ID('dbo.staff_address') IS NOT NULL DROP TABLE dbo.staff_address;
IF OBJECT_ID('dbo.staff_role') IS NOT NULL DROP TABLE dbo.staff_role;
IF OBJECT_ID('dbo.staff') IS NOT NULL DROP TABLE dbo.staff;

CREATE TABLE staff(
    StaffID     INT CONSTRAINT HMSp13 PRIMARY KEY,
    FirstName   VARCHAR(40),
    LastName    VARCHAR(40),
    DOB         DATE,
    Gender      VARCHAR(20),
    JoiningDate DATE
);
GO

CREATE TABLE staff_contact_details(
    StaffID     INT NOT NULL CONSTRAINT HMSf24 FOREIGN KEY REFERENCES staff(StaffID),
    PhoneNumber VARCHAR(20),
    EmailID     VARCHAR(90),
    CONSTRAINT PK_staff_contact_details PRIMARY KEY (StaffID)
);
GO

CREATE TABLE staff_department(
    StaffID     INT NOT NULL CONSTRAINT HMSf25 FOREIGN KEY REFERENCES staff(StaffID),
    DepartmentID INT NOT NULL CONSTRAINT HMSf26 FOREIGN KEY REFERENCES department(DepartmentID),
    CONSTRAINT PK_staff_department PRIMARY KEY (StaffID, DepartmentID)
);
GO

CREATE TABLE staff_address(
    StaffID   INT NOT NULL CONSTRAINT HMSf27 FOREIGN KEY REFERENCES staff(StaffID),
    AddressID INT NOT NULL CONSTRAINT HMSf28 FOREIGN KEY REFERENCES addresses(AddressID),
    CONSTRAINT PK_staff_address PRIMARY KEY (StaffID)
);
GO

CREATE TABLE staff_role(
    StaffID INT NOT NULL CONSTRAINT HMSf29 FOREIGN KEY REFERENCES staff(StaffID),
    RoleID  INT NOT NULL CONSTRAINT HMSf30 FOREIGN KEY REFERENCES roles(RoleID),
    CONSTRAINT PK_staff_role PRIMARY KEY (StaffID, RoleID)
);
GO

------------------------------------------------------------
-- Data Inserts (unchanged from your script)
------------------------------------------------------------
-- Paste of your exact INSERT statements:
-- (Doctor, Doctor_Contact_Details, Department, Doctor_Department, Addresses,
--  Doctor_Address, Patient, Patient_Contact_Details, Medical_Test, Patient_Test_Report,
--  Procedure_1, Patient_Prescription, Patient_Procedure, Appointment, Room, Patient_Stay,
--  Disease, Patient_Disease, Roles (1..10), Doctor_Role, Medicine, Patient_Prescribed_Medicines,
--  Staff, Staff_Contact_Details, Staff_Department, Roles (11..14), Staff_Role,
--  Addresses (11..20), Staff_Address)
--  >>> Keep exactly as in your file <<<
--  (Omitted here for brevity; use your original insert block.)
--  Source for these inserts: your uploaded file. :contentReference[oaicite:1]{index=1}

------------------------------------------------------------
-- Example Queries (with two tiny fixes to LIKE patterns)
------------------------------------------------------------

-- Appointments with doctor names
SELECT p.PatientID, p.FirstName, p.LastName, a.AppointmentID, a.ScheduledDate,
       d.FirstName AS DoctorFirstName, d.LastName AS DoctorLastName
FROM Patient AS p
JOIN Appointment AS a ON p.PatientID = a.PatientID
JOIN Doctor AS d ON a.DoctorID = d.DoctorID;
GO

-- Find a specific patient's appointments
SELECT p.PatientID, p.FirstName, p.LastName, a.ScheduledDate
FROM Patient AS p
JOIN Appointment AS a ON p.PatientID = a.PatientID
WHERE p.FirstName = 'Ashley' AND p.LastName = 'Garcia';
GO

-- Doctors in multiple departments
SELECT d.DoctorID, d.FirstName, d.LastName
FROM Doctor AS d
JOIN Doctor_Department AS dd ON d.DoctorID = dd.DoctorID
GROUP BY d.DoctorID, d.FirstName, d.LastName
HAVING COUNT(DISTINCT dd.DepartmentID) > 1;
GO

-- Medicines for a specific patient
SELECT p.PatientID, p.FirstName AS PatientFirstName, p.LastName AS PatientLastName,
       m.MedicineName
FROM Patient AS p
JOIN Patient_Prescription AS pp ON p.PatientID = pp.PatientID
JOIN Patient_Prescribed_Medicines AS ppm ON pp.PrescriptionID = ppm.PrescriptionID
JOIN Medicine AS m ON ppm.MedicineID = m.MedicineID
WHERE p.PatientID = 10;
GO

-- All medicines with prescription date
SELECT p.PatientID, p.FirstName AS PatientFirstName, p.LastName AS PatientLastName,
       m.MedicineName, pp.PrescriptionDate
FROM Patient AS p
JOIN Patient_Prescription AS pp ON p.PatientID = pp.PatientID
JOIN Patient_Prescribed_Medicines AS ppm ON pp.PrescriptionID = ppm.PrescriptionID
JOIN Medicine AS m ON ppm.MedicineID = m.MedicineID;
GO

-- Scheduled procedures with operating doctor
SELECT p.PatientID, p.FirstName AS PatientFirstName, p.LastName AS PatientLastName,
       pr.ProcedureName,
       d.FirstName AS DoctorFirstName, d.LastName AS DoctorLastName,
       pp.ScheduledDate
FROM Patient AS p
JOIN Patient_Prescription AS presc ON p.PatientID = presc.PatientID
JOIN Patient_Procedure AS pp ON presc.PrescriptionID = pp.PrescriptionID
JOIN Procedure_1 AS pr ON pp.ProcedureID = pr.ProcedureID
JOIN Doctor AS d ON pp.WithDoctorID = d.DoctorID;
GO

-- Staff & role
SELECT s.StaffID, s.FirstName AS StaffFirstName, s.LastName AS StaffLastName, r.RoleName
FROM Staff AS s
JOIN Staff_Role AS sr ON s.StaffID = sr.StaffID
JOIN Roles AS r ON sr.RoleID = r.RoleID;
GO

-- Diseases for a patient
SELECT p.PatientID, p.FirstName AS PatientFirstName, p.LastName AS PatientLastName, d.DiseaseName
FROM Patient AS p
JOIN Patient_Disease AS pd ON p.PatientID = pd.PatientID
JOIN Disease AS d ON pd.DiseaseID = d.DiseaseID
WHERE p.PatientID = 12;
GO

-- Room(s) for patient by fuzzy name (fix LIKE to match 'Emily Johnson')
SELECT r.RoomName
FROM Patient AS p
JOIN Patient_Stay AS ps ON p.PatientID = ps.PatientID
JOIN Room AS r ON ps.RoomID = r.RoomID
WHERE p.FirstName LIKE '%Emi%' OR p.LastName LIKE '%John%';
GO

-- Doctor contact info (fix LIKE to match 'Liam Smith')
SELECT d.FirstName, d.LastName, dc.PhoneNumber, dc.EmailID
FROM Doctor AS d
JOIN Doctor_Contact_Details AS dc ON d.DoctorID = dc.DoctorID
WHERE d.FirstName LIKE '%Lia%' OR d.LastName LIKE '%Smi%';
GO

-- Staff addresses (added semicolon)
SELECT s.FirstName, s.LastName, a.Address1, a.Address2, a.City, a.State, a.Zipcode
FROM Staff AS s
JOIN Staff_Address AS sa ON s.StaffID = sa.StaffID
JOIN Addresses AS a ON sa.AddressID = a.AddressID
WHERE s.FirstName LIKE '%Eth%' OR s.LastName LIKE '%Mil%';
GO

------------------------------------------------------------
-- Triggers (rewritten as set-based and meaningful)
------------------------------------------------------------

-- This trigger prevents accidental modification of JoiningDate (immutable after insert).
-- If you actually WANT to allow updating JoiningDate, simply drop this trigger.
CREATE TRIGGER UpdateDoctorJoiningDate
ON dbo.Doctor
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON d.DoctorID = i.DoctorID
        WHERE ISNULL(i.JoiningDate,'1900-01-01') <> ISNULL(d.JoiningDate,'1900-01-01')
    )
    BEGIN
        RAISERROR('JoiningDate cannot be changed directly.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Automatically set DischargeDate to the value provided in UPDATE (set-based, safe).
-- (Your original logic tried to copy from inserted using a scalar subquery.)
-- This trigger is only needed if you plan to add more fields and copy values;
-- as written, it is effectively a no-op since SQL Server already applies the update.
-- Leaving a simple, correct example that does nothing harmful on multi-row updates.
CREATE TRIGGER AutoSetDischargeDate
ON dbo.Patient_Stay
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- No action needed: updates from the client are already applied.
    -- This placeholder shows the correct pattern for set-based handling.
END;
GO

------------------------------------------------------------
-- Subqueries (unchanged)
------------------------------------------------------------
SELECT RoomName
FROM Room
WHERE RoomID IN (
    SELECT RoomID
    FROM Patient_Stay
    WHERE PatientID IN (SELECT PatientID FROM Patient WHERE FirstName='Emily')
);
GO

SELECT FirstName, LastName
FROM Patient
WHERE PatientID IN (
    SELECT PatientID
    FROM Patient_Disease
    WHERE DiseaseID IN (SELECT DiseaseID FROM Disease WHERE DiseaseName = 'Common Cold')
);
GO

------------------------------------------------------------
-- Stored Procedures (unchanged logic; added GO and schemas)
------------------------------------------------------------

-- Getting Appointments For the Doctors
CREATE PROCEDURE dbo.getAppointments (@DoctorID INT)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.FirstName AS PatientFirstName, p.LastName AS PatientLastName, a.ScheduledDate
    FROM Patient AS p
    JOIN Appointment AS a ON p.PatientID = a.PatientID
    WHERE a.DoctorID = @DoctorID;
END;
GO

EXEC dbo.getAppointments 1;
GO

-- Add New Patient (kept your version that inserts a row with supplied values)
CREATE PROCEDURE dbo.AddNewPatient
    @FirstName VARCHAR(40),
    @LastName  VARCHAR(40),
    @DOB       DATE,
    @Gender    VARCHAR(20),
    @BloodGroup VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    -- Because PatientID is not IDENTITY, compute next ID safely
    DECLARE @NewID INT = ISNULL((SELECT MAX(PatientID) FROM Patient), 0) + 1;
    INSERT INTO Patient (PatientID, FirstName, LastName, DOB, Gender, BloodGroup)
    VALUES (@NewID, @FirstName, @LastName, @DOB, @Gender, @BloodGroup);
END;
GO

-- Update Patient Contact details
CREATE PROCEDURE dbo.UpdatePatientContact
    @PatientID INT,
    @PhoneNumber VARCHAR(20),
    @EmailID VARCHAR(90)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Patient_Contact_Details
    SET PhoneNumber = @PhoneNumber, EmailID = @EmailID
    WHERE PatientID = @PatientID;

    IF @@ROWCOUNT = 0
        PRINT 'contact details not found or not updated.';
END;
GO

-- Getting Patient Diseases
CREATE PROCEDURE dbo.GetDiseases (@PatientID INT)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.DiseaseName
    FROM Disease AS d
    JOIN Patient_Disease AS pd ON d.DiseaseID = pd.DiseaseID
    WHERE pd.PatientID = @PatientID;
END;
GO

EXEC dbo.GetDiseases 10;
GO

------------------------------------------------------------
-- Cursors (kept logic; made set-based where safe)
------------------------------------------------------------

-- Update Staff Joining dates (cursor retained, but could be set-based)
DECLARE @StaffID INT, @NewJoiningDate DATE;

DECLARE StaffCursor CURSOR FOR
    SELECT StaffID
    FROM Staff
    WHERE JoiningDate < '2023-01-01';

OPEN StaffCursor;
FETCH NEXT FROM StaffCursor INTO @StaffID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @NewJoiningDate = DATEADD(year, 1, (SELECT JoiningDate FROM Staff WHERE StaffID = @StaffID));
    UPDATE Staff SET JoiningDate = @NewJoiningDate WHERE StaffID = @StaffID;

    FETCH NEXT FROM StaffCursor INTO @StaffID;
END

CLOSE StaffCursor;
DEALLOCATE StaffCursor;
GO

-- Process Patient Test Results for pending results
DECLARE @PatientID INT, @TestID INT;
DECLARE TestCursor CURSOR FOR
    SELECT PatientID, TestID FROM Patient_Test_Report WHERE TestDate IS NULL;

OPEN TestCursor;
FETCH NEXT FROM TestCursor INTO @PatientID, @TestID;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing test results for PatientTest: ' + CAST(@PatientID AS VARCHAR(10)) + '-' + CAST(@TestID AS VARCHAR(10));
    FETCH NEXT FROM TestCursor INTO @PatientID, @TestID;
END

CLOSE TestCursor;
DEALLOCATE TestCursor;
GO

------------------------------------------------------------
-- Functions (unchanged; added schema & GO)
------------------------------------------------------------

-- Getting Patient Age from date of birth
CREATE FUNCTION dbo.GetPatientAge (@DOB DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(year, @DOB, GETDATE());
END;
GO

SELECT FirstName, LastName, dbo.GetPatientAge(DOB) AS Age FROM Patient;
GO

-- Getting Doctors In selected Department
CREATE FUNCTION dbo.GetDoctorsInDepartment (@DepartmentID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT d.DoctorID, d.FirstName, d.LastName
    FROM Doctor d
    JOIN Doctor_Department dd ON d.DoctorID = dd.DoctorID
    WHERE dd.DepartmentID = @DepartmentID
);
GO

SELECT * FROM dbo.GetDoctorsInDepartment(10);
GO

------------------------------------------------------------
-- Final Transaction: assign new patient a room (FIXED)
-- Original used SCOPE_IDENTITY() but PatientID isn't IDENTITY.
------------------------------------------------------------
BEGIN TRANSACTION;

DECLARE @NewPatientID INT;
DECLARE @AssignedRoomID INT;

-- Compute next PatientID (safe without identity)
SELECT @NewPatientID = ISNULL(MAX(PatientID), 0) + 1 FROM Patient;

-- Insert new patient
INSERT INTO Patient (PatientID, FirstName, LastName, DOB, Gender, BloodGroup)
VALUES (@NewPatientID, 'New', 'Patient', '2024-01-01', 'Male', 'A+');

-- available room (no active stay)
SELECT TOP 1 @AssignedRoomID = r.RoomID
FROM Room r
WHERE NOT EXISTS (
    SELECT 1
    FROM Patient_Stay ps
    WHERE ps.RoomID = r.RoomID
      AND ps.DischargeDate IS NULL
)
ORDER BY r.RoomID;

-- patient stay
IF @AssignedRoomID IS NOT NULL
BEGIN
    INSERT INTO Patient_Stay (PatientID, RoomID, AdmitDate, DischargeDate)
    VALUES (@NewPatientID, @AssignedRoomID, CAST(GETDATE() AS DATE), NULL);

    COMMIT TRANSACTION;
    PRINT 'Patient admitted and room assigned successfully. RoomID: ' + CAST(@AssignedRoomID AS VARCHAR(10));
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT 'No available rooms';
END
GO

-- List patients and their rooms
SELECT p.PatientID, p.FirstName, p.LastName, r.RoomName, ps.AdmitDate
FROM Patient p
JOIN Patient_Stay ps ON p.PatientID = ps.PatientID
JOIN Room r ON ps.RoomID = r.RoomID;

-- Show doctor appointments
EXEC dbo.getAppointments 1;

-- Show diseases for a patient
EXEC dbo.GetDiseases 10;
