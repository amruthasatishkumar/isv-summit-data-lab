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
