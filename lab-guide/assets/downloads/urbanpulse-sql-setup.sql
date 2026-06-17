-- =============================================================
-- UrbanPulse - Azure SQL setup for Fabric Mirroring (single script)
-- Merged: schema + seed data + Change Tracking enable.
-- Run against YOUR OWN Azure SQL Database (not the shared server).
-- Idempotent: safe to re-run. Paste into the Azure Portal Query
-- editor or SSMS/Azure Data Studio and execute top to bottom.
-- =============================================================
-- =============================================================
-- UrbanPulse city-ops schema for Azure SQL Database
-- Lab-safe: drops + recreates tables. Run in any order against
-- a fresh database; safe to re-run.
-- =============================================================

IF OBJECT_ID('dbo.Staff', 'U')      IS NOT NULL DROP TABLE dbo.Staff;
IF OBJECT_ID('dbo.Wards', 'U')      IS NOT NULL DROP TABLE dbo.Wards;
IF OBJECT_ID('dbo.Hospitals', 'U')  IS NOT NULL DROP TABLE dbo.Hospitals;

-- Drop pre-existing edu data if present (older lab versions)
IF OBJECT_ID('dbo.Enrollments', 'U') IS NOT NULL DROP TABLE dbo.Enrollments;
IF OBJECT_ID('dbo.Classes', 'U')     IS NOT NULL DROP TABLE dbo.Classes;
IF OBJECT_ID('dbo.Students', 'U')    IS NOT NULL DROP TABLE dbo.Students;

GO

CREATE TABLE dbo.Hospitals (
    hospitalId   VARCHAR(8)    NOT NULL PRIMARY KEY,   -- e.g. H-1
    name         NVARCHAR(120) NOT NULL,
    regionId     VARCHAR(16)   NOT NULL,               -- joins to Cosmos regions
    facilityType VARCHAR(32)   NOT NULL,               -- Tertiary | Academic | Community | Specialty
    beds         INT           NOT NULL,
    icuBeds      INT           NOT NULL,
    openedYear   SMALLINT      NOT NULL,
    address      NVARCHAR(200) NULL,
    createdAt    DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Wards (
    wardId       VARCHAR(8)    NOT NULL PRIMARY KEY,   -- e.g. W-101
    hospitalId   VARCHAR(8)    NOT NULL,
    code         VARCHAR(8)    NOT NULL,               -- ER | ICU | MED | PED | OB | OBS
    name         NVARCHAR(60)  NOT NULL,
    capacity     INT           NOT NULL,
    CONSTRAINT FK_Wards_Hospitals
        FOREIGN KEY (hospitalId) REFERENCES dbo.Hospitals(hospitalId)
);

CREATE TABLE dbo.Staff (
    staffId       VARCHAR(8)    NOT NULL PRIMARY KEY,  -- e.g. S-1001
    hospitalId    VARCHAR(8)    NOT NULL,
    fullName      NVARCHAR(120) NOT NULL,
    role          VARCHAR(20)   NOT NULL,              -- Nurse | Physician | Tech | EMS | Admin | Housekeeping
    shift         VARCHAR(10)   NOT NULL,              -- Day | Night | Swing
    onCall        BIT           NOT NULL DEFAULT 0,
    hireDate      DATE          NOT NULL,
    CONSTRAINT FK_Staff_Hospitals
        FOREIGN KEY (hospitalId) REFERENCES dbo.Hospitals(hospitalId)
);

CREATE INDEX IX_Wards_HospitalId ON dbo.Wards(hospitalId);
CREATE INDEX IX_Staff_HospitalId ON dbo.Staff(hospitalId);
CREATE INDEX IX_Hospitals_RegionId ON dbo.Hospitals(regionId);

GO

GO

-- =============================================================
-- UrbanPulse seed data. Generated from seed-data/shared/ids.json.
-- Re-run by: python seed-data\sql\generate_seed_sql.py
-- =============================================================
SET NOCOUNT ON;
BEGIN TRANSACTION;

DELETE FROM dbo.Staff;
DELETE FROM dbo.Wards;
DELETE FROM dbo.Hospitals;

-- Hospitals
INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address) VALUES ('H-1', N'North District Medical Center', 'R-NORTH', 'Tertiary', 420, 48, 1978, N'43321 Brittany Bypass, Metropolis');
INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address) VALUES ('H-2', N'Loop General Hospital', 'R-LOOP', 'Academic', 612, 72, 1925, N'33890 Jennifer Squares, Metropolis');
INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address) VALUES ('H-3', N'West Side Community Hospital', 'R-WEST', 'Community', 180, 16, 1992, N'79402 Peterson Drives Apt. 511, Metropolis');
INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address) VALUES ('H-4', N'South Lakeshore Medical', 'R-SOUTH', 'Tertiary', 360, 40, 1985, N'55940 Herrera Lane Apt. 849, Metropolis');
INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address) VALUES ('H-5', N'Airport Urgent Care Center', 'R-AIRPORT', 'Specialty', 60, 6, 2014, N'310 Kendra Common Apt. 164, Metropolis');

-- Wards (6 per hospital)
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-101', 'H-1', 'ER', N'Emergency Department', 24);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-102', 'H-1', 'ICU', N'Intensive Care Unit', 16);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-103', 'H-1', 'MED', N'Medical / Surgical', 40);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-104', 'H-1', 'PED', N'Pediatrics', 20);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-105', 'H-1', 'OB', N'Maternity', 18);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-106', 'H-1', 'OBS', N'Observation', 12);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-201', 'H-2', 'ER', N'Emergency Department', 24);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-202', 'H-2', 'ICU', N'Intensive Care Unit', 16);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-203', 'H-2', 'MED', N'Medical / Surgical', 40);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-204', 'H-2', 'PED', N'Pediatrics', 20);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-205', 'H-2', 'OB', N'Maternity', 18);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-206', 'H-2', 'OBS', N'Observation', 12);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-301', 'H-3', 'ER', N'Emergency Department', 24);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-302', 'H-3', 'ICU', N'Intensive Care Unit', 16);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-303', 'H-3', 'MED', N'Medical / Surgical', 40);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-304', 'H-3', 'PED', N'Pediatrics', 20);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-305', 'H-3', 'OB', N'Maternity', 18);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-306', 'H-3', 'OBS', N'Observation', 12);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-401', 'H-4', 'ER', N'Emergency Department', 24);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-402', 'H-4', 'ICU', N'Intensive Care Unit', 16);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-403', 'H-4', 'MED', N'Medical / Surgical', 40);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-404', 'H-4', 'PED', N'Pediatrics', 20);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-405', 'H-4', 'OB', N'Maternity', 18);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-406', 'H-4', 'OBS', N'Observation', 12);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-501', 'H-5', 'ER', N'Emergency Department', 24);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-502', 'H-5', 'ICU', N'Intensive Care Unit', 16);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-503', 'H-5', 'MED', N'Medical / Surgical', 40);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-504', 'H-5', 'PED', N'Pediatrics', 20);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-505', 'H-5', 'OB', N'Maternity', 18);
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ('W-506', 'H-5', 'OBS', N'Observation', 12);

-- Staff (30 per hospital)
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1001', 'H-1', N'Roy Martin', 'Nurse', 'Swing', 1, '2023-09-01');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1002', 'H-1', N'Michael Miles', 'Nurse', 'Day', 0, '2023-08-19');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1003', 'H-1', N'Andrea Reid', 'Nurse', 'Night', 0, '2023-08-06');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1004', 'H-1', N'Danielle Ford', 'Nurse', 'Swing', 0, '2023-07-24');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1005', 'H-1', N'Timothy Watts', 'Nurse', 'Day', 0, '2023-07-11');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1006', 'H-1', N'Frederick Tate', 'Nurse', 'Night', 0, '2023-06-28');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1007', 'H-1', N'Rodney Trujillo', 'Nurse', 'Swing', 0, '2023-06-15');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1008', 'H-1', N'Austin Gentry', 'Nurse', 'Day', 1, '2023-06-02');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1009', 'H-1', N'Michelle Lewis', 'Physician', 'Night', 0, '2023-05-20');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1010', 'H-1', N'Dr. Marvin Thomas Jr.', 'Physician', 'Swing', 0, '2023-05-07');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1011', 'H-1', N'Kimberly Burgess', 'Physician', 'Day', 0, '2023-04-24');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1012', 'H-1', N'Kevin Cox', 'Physician', 'Night', 0, '2023-04-11');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1013', 'H-1', N'Brenda Snyder PhD', 'Physician', 'Swing', 0, '2023-03-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1014', 'H-1', N'Brittany Moore', 'Physician', 'Day', 0, '2023-03-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1015', 'H-1', N'Linda Cruz', 'Tech', 'Night', 1, '2023-03-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1016', 'H-1', N'Julie King', 'Tech', 'Swing', 0, '2023-02-18');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1017', 'H-1', N'Terri Frazier', 'Tech', 'Day', 0, '2023-02-05');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1018', 'H-1', N'Stephen Potter', 'Tech', 'Night', 0, '2023-01-23');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1019', 'H-1', N'Gina Carter', 'EMS', 'Swing', 0, '2023-01-10');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1020', 'H-1', N'Aaron Bowen', 'EMS', 'Day', 0, '2022-12-28');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1021', 'H-1', N'Valerie Gill', 'EMS', 'Night', 0, '2022-12-15');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1022', 'H-1', N'Ashley Garrett', 'EMS', 'Swing', 1, '2022-12-02');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1023', 'H-1', N'Katie Gonzalez', 'Admin', 'Day', 0, '2022-11-19');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1024', 'H-1', N'Christopher Ashley', 'Admin', 'Night', 0, '2022-11-06');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1025', 'H-1', N'Tamara George', 'Admin', 'Swing', 0, '2022-10-24');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1026', 'H-1', N'Brian Cox DVM', 'Admin', 'Day', 0, '2022-10-11');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1027', 'H-1', N'Cynthia Allen', 'Housekeeping', 'Night', 0, '2022-09-28');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1028', 'H-1', N'Angela Dennis', 'Housekeeping', 'Swing', 0, '2022-09-15');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1029', 'H-1', N'Vanessa Patel', 'Housekeeping', 'Day', 1, '2022-09-02');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1030', 'H-1', N'Matthew Arroyo', 'Housekeeping', 'Night', 0, '2022-08-20');

INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1031', 'H-2', N'Joseph Obrien', 'Nurse', 'Swing', 0, '2022-08-07');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1032', 'H-2', N'Tanya Campos', 'Nurse', 'Day', 0, '2022-07-25');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1033', 'H-2', N'Michelle Ross', 'Nurse', 'Night', 0, '2022-07-12');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1034', 'H-2', N'Jacqueline Lam', 'Nurse', 'Swing', 0, '2022-06-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1035', 'H-2', N'David Brown', 'Nurse', 'Day', 0, '2022-06-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1036', 'H-2', N'Julian Chapman', 'Nurse', 'Night', 1, '2022-06-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1037', 'H-2', N'Michael Brown', 'Nurse', 'Swing', 0, '2022-05-21');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1038', 'H-2', N'Andre Rivera', 'Nurse', 'Day', 0, '2022-05-08');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1039', 'H-2', N'Diana Washington', 'Physician', 'Night', 0, '2022-04-25');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1040', 'H-2', N'Miranda Khan', 'Physician', 'Swing', 0, '2022-04-12');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1041', 'H-2', N'Dana Kennedy', 'Physician', 'Day', 0, '2022-03-30');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1042', 'H-2', N'Brandon Hopkins', 'Physician', 'Night', 0, '2022-03-17');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1043', 'H-2', N'Jason Shields', 'Physician', 'Swing', 1, '2022-03-04');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1044', 'H-2', N'Matthew Lucas', 'Physician', 'Day', 0, '2022-02-19');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1045', 'H-2', N'Nicholas Mcbride', 'Tech', 'Night', 0, '2022-02-06');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1046', 'H-2', N'Corey Herrera', 'Tech', 'Swing', 0, '2022-01-24');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1047', 'H-2', N'Clifford Ford', 'Tech', 'Day', 0, '2022-01-11');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1048', 'H-2', N'Angela Morton', 'Tech', 'Night', 0, '2021-12-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1049', 'H-2', N'Annette Pearson', 'EMS', 'Swing', 0, '2021-12-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1050', 'H-2', N'Alexis Davis', 'EMS', 'Day', 1, '2021-12-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1051', 'H-2', N'Cynthia Russell', 'EMS', 'Night', 0, '2021-11-20');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1052', 'H-2', N'Dr. Steven Martin', 'EMS', 'Swing', 0, '2021-11-07');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1053', 'H-2', N'James House', 'Admin', 'Day', 0, '2021-10-25');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1054', 'H-2', N'Dominique Horton', 'Admin', 'Night', 0, '2021-10-12');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1055', 'H-2', N'Rachel Stanley', 'Admin', 'Swing', 0, '2021-09-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1056', 'H-2', N'Mr. Daniel Brown', 'Admin', 'Day', 0, '2021-09-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1057', 'H-2', N'Amy Edwards', 'Housekeeping', 'Night', 1, '2021-09-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1058', 'H-2', N'John Calhoun', 'Housekeeping', 'Swing', 0, '2021-08-21');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1059', 'H-2', N'Amy Romero', 'Housekeeping', 'Day', 0, '2021-08-08');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1060', 'H-2', N'Andrea Jones', 'Housekeeping', 'Night', 0, '2021-07-26');

INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1061', 'H-3', N'Jennifer David', 'Nurse', 'Swing', 0, '2021-07-13');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1062', 'H-3', N'Lauren Williams', 'Nurse', 'Day', 0, '2021-06-30');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1063', 'H-3', N'Matthew Cunningham', 'Nurse', 'Night', 0, '2021-06-17');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1064', 'H-3', N'Dean Santiago', 'Nurse', 'Swing', 1, '2021-06-04');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1065', 'H-3', N'Derek Anderson', 'Nurse', 'Day', 0, '2021-05-22');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1066', 'H-3', N'Joyce Hickman', 'Nurse', 'Night', 0, '2021-05-09');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1067', 'H-3', N'Alexandra Howell', 'Nurse', 'Swing', 0, '2021-04-26');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1068', 'H-3', N'Ariel Medina', 'Nurse', 'Day', 0, '2021-04-13');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1069', 'H-3', N'Brandi Bailey', 'Physician', 'Night', 0, '2021-03-31');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1070', 'H-3', N'David Mitchell', 'Physician', 'Swing', 0, '2021-03-18');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1071', 'H-3', N'Joshua Turner', 'Physician', 'Day', 1, '2021-03-05');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1072', 'H-3', N'Dr. Kendra Contreras', 'Physician', 'Night', 0, '2021-02-20');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1073', 'H-3', N'Tara Garcia', 'Physician', 'Swing', 0, '2021-02-07');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1074', 'H-3', N'Deborah Preston', 'Physician', 'Day', 0, '2021-01-25');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1075', 'H-3', N'Brittney Campbell', 'Tech', 'Night', 0, '2021-01-12');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1076', 'H-3', N'Grant Watts', 'Tech', 'Swing', 0, '2020-12-30');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1077', 'H-3', N'Kathy King', 'Tech', 'Day', 0, '2020-12-17');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1078', 'H-3', N'Amber Walters', 'Tech', 'Night', 1, '2020-12-04');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1079', 'H-3', N'Amanda Cook', 'EMS', 'Swing', 0, '2020-11-21');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1080', 'H-3', N'William Martin', 'EMS', 'Day', 0, '2020-11-08');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1081', 'H-3', N'Michael Hoffman', 'EMS', 'Night', 0, '2020-10-26');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1082', 'H-3', N'Tony Vazquez', 'EMS', 'Swing', 0, '2020-10-13');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1083', 'H-3', N'Andrew Wood', 'Admin', 'Day', 0, '2020-09-30');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1084', 'H-3', N'Jessica Williams', 'Admin', 'Night', 0, '2020-09-17');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1085', 'H-3', N'Timothy Stanton', 'Admin', 'Swing', 1, '2020-09-04');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1086', 'H-3', N'Hunter Fleming', 'Admin', 'Day', 0, '2020-08-22');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1087', 'H-3', N'Heather Castro', 'Housekeeping', 'Night', 0, '2020-08-09');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1088', 'H-3', N'Valerie Brady', 'Housekeeping', 'Swing', 0, '2020-07-27');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1089', 'H-3', N'Cynthia Martin', 'Housekeeping', 'Day', 0, '2020-07-14');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1090', 'H-3', N'Cassandra Gutierrez', 'Housekeeping', 'Night', 0, '2020-07-01');

INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1091', 'H-4', N'Tim Patton', 'Nurse', 'Swing', 0, '2020-06-18');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1092', 'H-4', N'Michael Moss', 'Nurse', 'Day', 1, '2020-06-05');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1093', 'H-4', N'Christopher Haynes', 'Nurse', 'Night', 0, '2020-05-23');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1094', 'H-4', N'Andrew Ruiz', 'Nurse', 'Swing', 0, '2020-05-10');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1095', 'H-4', N'Thomas Bailey', 'Nurse', 'Day', 0, '2020-04-27');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1096', 'H-4', N'Shelby Walker', 'Nurse', 'Night', 0, '2020-04-14');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1097', 'H-4', N'Jennifer Ramirez', 'Nurse', 'Swing', 0, '2020-04-01');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1098', 'H-4', N'Raymond Bell', 'Nurse', 'Day', 0, '2020-03-19');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1099', 'H-4', N'Meghan Anthony', 'Physician', 'Night', 1, '2020-03-06');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1100', 'H-4', N'Alexander Wiley', 'Physician', 'Swing', 0, '2020-02-22');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1101', 'H-4', N'Kevin Terrell', 'Physician', 'Day', 0, '2020-02-09');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1102', 'H-4', N'Kyle Reed', 'Physician', 'Night', 0, '2020-01-27');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1103', 'H-4', N'Jessica Joyce', 'Physician', 'Swing', 0, '2020-01-14');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1104', 'H-4', N'Steven Lee', 'Physician', 'Day', 0, '2020-01-01');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1105', 'H-4', N'Jeffrey Meyer', 'Tech', 'Night', 0, '2019-12-19');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1106', 'H-4', N'Melissa Bentley', 'Tech', 'Swing', 1, '2019-12-06');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1107', 'H-4', N'Christina Reynolds', 'Tech', 'Day', 0, '2019-11-23');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1108', 'H-4', N'Tammie Hanson', 'Tech', 'Night', 0, '2019-11-10');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1109', 'H-4', N'Belinda Mccullough', 'EMS', 'Swing', 0, '2019-10-28');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1110', 'H-4', N'Mary Nguyen', 'EMS', 'Day', 0, '2019-10-15');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1111', 'H-4', N'Kristen Lee', 'EMS', 'Night', 0, '2019-10-02');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1112', 'H-4', N'Jamie Adkins', 'EMS', 'Swing', 0, '2019-09-19');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1113', 'H-4', N'Keith Sullivan', 'Admin', 'Day', 1, '2019-09-06');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1114', 'H-4', N'Elizabeth Clark', 'Admin', 'Night', 0, '2019-08-24');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1115', 'H-4', N'Lisa Morris', 'Admin', 'Swing', 0, '2019-08-11');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1116', 'H-4', N'Michael Dixon', 'Admin', 'Day', 0, '2019-07-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1117', 'H-4', N'Toni Fitzgerald', 'Housekeeping', 'Night', 0, '2019-07-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1118', 'H-4', N'Diane Beck', 'Housekeeping', 'Swing', 0, '2019-07-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1119', 'H-4', N'Anna Crane', 'Housekeeping', 'Day', 0, '2019-06-20');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1120', 'H-4', N'Eric Drake', 'Housekeeping', 'Night', 1, '2019-06-07');

INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1121', 'H-5', N'Angel Riggs', 'Nurse', 'Swing', 0, '2019-05-25');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1122', 'H-5', N'Patricia Gibson', 'Nurse', 'Day', 0, '2019-05-12');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1123', 'H-5', N'Laura Higgins', 'Nurse', 'Night', 0, '2019-04-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1124', 'H-5', N'James Hernandez', 'Nurse', 'Swing', 0, '2019-04-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1125', 'H-5', N'Stephanie Dalton', 'Nurse', 'Day', 0, '2019-04-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1126', 'H-5', N'Paula Robinson', 'Nurse', 'Night', 0, '2019-03-21');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1127', 'H-5', N'Melissa Marshall', 'Nurse', 'Swing', 1, '2019-03-08');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1128', 'H-5', N'Sylvia Martinez', 'Nurse', 'Day', 0, '2019-02-23');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1129', 'H-5', N'John Schmidt', 'Physician', 'Night', 0, '2019-02-10');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1130', 'H-5', N'Emily Fischer', 'Physician', 'Swing', 0, '2019-01-28');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1131', 'H-5', N'Robert Mcclain', 'Physician', 'Day', 0, '2019-01-15');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1132', 'H-5', N'Terry Griffin', 'Physician', 'Night', 0, '2019-01-02');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1133', 'H-5', N'Scott Cole', 'Physician', 'Swing', 0, '2018-12-20');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1134', 'H-5', N'Sara Ramirez', 'Physician', 'Day', 1, '2018-12-07');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1135', 'H-5', N'Kari Allen', 'Tech', 'Night', 0, '2018-11-24');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1136', 'H-5', N'Micheal Young', 'Tech', 'Swing', 0, '2018-11-11');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1137', 'H-5', N'Steven Miller', 'Tech', 'Day', 0, '2018-10-29');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1138', 'H-5', N'James Hernandez', 'Tech', 'Night', 0, '2018-10-16');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1139', 'H-5', N'Jason Rivera', 'EMS', 'Swing', 0, '2018-10-03');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1140', 'H-5', N'Antonio Wall', 'EMS', 'Day', 0, '2018-09-20');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1141', 'H-5', N'Randy Shah', 'EMS', 'Night', 1, '2018-09-07');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1142', 'H-5', N'Spencer Johnston', 'EMS', 'Swing', 0, '2018-08-25');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1143', 'H-5', N'Tommy Evans', 'Admin', 'Day', 0, '2018-08-12');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1144', 'H-5', N'Steven Houston', 'Admin', 'Night', 0, '2018-07-30');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1145', 'H-5', N'Morgan Marsh', 'Admin', 'Swing', 0, '2018-07-17');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1146', 'H-5', N'Katherine Nelson', 'Admin', 'Day', 0, '2018-07-04');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1147', 'H-5', N'Mr. Michael Yates', 'Housekeeping', 'Night', 0, '2018-06-21');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1148', 'H-5', N'Sara Calhoun', 'Housekeeping', 'Swing', 1, '2018-06-08');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1149', 'H-5', N'Ms. Susan Vargas', 'Housekeeping', 'Day', 0, '2018-05-26');
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ('S-1150', 'H-5', N'Angela Patterson', 'Housekeeping', 'Night', 0, '2018-05-13');

COMMIT;

-- Sanity counts
SELECT 'Hospitals' AS [table], COUNT(*) AS rows FROM dbo.Hospitals
UNION ALL SELECT 'Wards',     COUNT(*) FROM dbo.Wards
UNION ALL SELECT 'Staff',     COUNT(*) FROM dbo.Staff;

-- =============================================================
-- Enable Change Tracking (required for Fabric Mirroring)
-- =============================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_databases
    WHERE database_id = DB_ID()
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'ALTER DATABASE [' + DB_NAME() + N']
        SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 1 DAYS, AUTO_CLEANUP = ON);';
    EXEC (@sql);
END;
GO

ALTER TABLE dbo.Hospitals ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
ALTER TABLE dbo.Wards     ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
ALTER TABLE dbo.Staff     ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
GO
