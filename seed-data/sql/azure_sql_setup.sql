-- =============================================================
-- UrbanPulse - Azure SQL setup for Fabric Mirroring lab
-- Self-contained: schema + bulk seed (>= 100 rows per table) +
-- Change Tracking enable. Paste into Azure Portal Query editor
-- (or SSMS) and click Run. Idempotent: safe to re-run.
-- Target: Azure SQL Database (Hyperscale or General Purpose).
-- =============================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ---- 1. Drop existing (lab-safe) ----
IF OBJECT_ID('dbo.Staff', 'U')     IS NOT NULL DROP TABLE dbo.Staff;
IF OBJECT_ID('dbo.Wards', 'U')     IS NOT NULL DROP TABLE dbo.Wards;
IF OBJECT_ID('dbo.Hospitals', 'U') IS NOT NULL DROP TABLE dbo.Hospitals;
GO

-- ---- 2. Schema ----
CREATE TABLE dbo.Hospitals (
    hospitalId   VARCHAR(8)    NOT NULL PRIMARY KEY,
    name         NVARCHAR(120) NOT NULL,
    regionId     VARCHAR(16)   NOT NULL,
    facilityType VARCHAR(32)   NOT NULL,
    beds         INT           NOT NULL,
    icuBeds      INT           NOT NULL,
    openedYear   SMALLINT      NOT NULL,
    address      NVARCHAR(200) NULL,
    createdAt    DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Wards (
    wardId       VARCHAR(12)   NOT NULL PRIMARY KEY,
    hospitalId   VARCHAR(8)    NOT NULL,
    code         VARCHAR(8)    NOT NULL,
    name         NVARCHAR(60)  NOT NULL,
    capacity     INT           NOT NULL,
    CONSTRAINT FK_Wards_Hospitals
        FOREIGN KEY (hospitalId) REFERENCES dbo.Hospitals(hospitalId)
);

CREATE TABLE dbo.Staff (
    staffId       VARCHAR(12)   NOT NULL PRIMARY KEY,
    hospitalId    VARCHAR(8)    NOT NULL,
    fullName      NVARCHAR(120) NOT NULL,
    role          VARCHAR(20)   NOT NULL,
    shift         VARCHAR(10)   NOT NULL,
    onCall        BIT           NOT NULL DEFAULT 0,
    hireDate      DATE          NOT NULL,
    CONSTRAINT FK_Staff_Hospitals
        FOREIGN KEY (hospitalId) REFERENCES dbo.Hospitals(hospitalId)
);

CREATE INDEX IX_Wards_HospitalId  ON dbo.Wards(hospitalId);
CREATE INDEX IX_Staff_HospitalId  ON dbo.Staff(hospitalId);
CREATE INDEX IX_Hospitals_Region  ON dbo.Hospitals(regionId);
GO

-- ---- 3. Numbers helper (CTE-based, no permanent object) ----
-- Used to generate 100/600/1000 rows in set-based fashion.

-- ---- 4. Seed Hospitals (100 rows) ----
;WITH N AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address)
SELECT
    'H-' + CAST(n AS VARCHAR(8)),
    CASE n
        WHEN 1 THEN N'North District Medical Center'
        WHEN 2 THEN N'Loop General Hospital'
        WHEN 3 THEN N'West Side Community Hospital'
        WHEN 4 THEN N'South Lakeshore Medical'
        WHEN 5 THEN N'Airport Urgent Care Center'
        ELSE N'UrbanPulse Hospital ' + CAST(n AS NVARCHAR(8))
    END,
    CASE (n - 1) % 5
        WHEN 0 THEN 'R-NORTH'
        WHEN 1 THEN 'R-LOOP'
        WHEN 2 THEN 'R-WEST'
        WHEN 3 THEN 'R-SOUTH'
        ELSE        'R-AIRPORT'
    END,
    CASE (n - 1) % 4
        WHEN 0 THEN 'Tertiary'
        WHEN 1 THEN 'Academic'
        WHEN 2 THEN 'Community'
        ELSE        'Specialty'
    END,
    60 + ((n * 17) % 580),
    6  + ((n * 3)  % 80),
    CAST(1925 + ((n * 11) % 100) AS SMALLINT),
    N'Lab address ' + CAST(n AS NVARCHAR(8)) + N', Metropolis'
FROM N;
GO

-- ---- 5. Seed Wards (6 per hospital -> 600 rows) ----
;WITH WardTypes AS (
    SELECT * FROM (VALUES
        (1, 'ER',  N'Emergency Department', 24),
        (2, 'ICU', N'Intensive Care Unit',  16),
        (3, 'MED', N'Medical / Surgical',   40),
        (4, 'PED', N'Pediatrics',           20),
        (5, 'OB',  N'Maternity',            18),
        (6, 'OBS', N'Observation',          12)
    ) AS w(seq, code, name, capacity)
)
INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity)
SELECT
    'W-' + RIGHT('000' + CAST(h.idx AS VARCHAR(3)), 3) + CAST(w.seq AS VARCHAR(1)),
    h.hospitalId,
    w.code,
    w.name,
    w.capacity
FROM (
    SELECT hospitalId,
           CAST(SUBSTRING(hospitalId, 3, 8) AS INT) AS idx
    FROM dbo.Hospitals
) h
CROSS JOIN WardTypes w;
GO

-- ---- 6. Seed Staff (10 per hospital -> 1000 rows) ----
;WITH N AS (
    SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
), Roles AS (
    SELECT * FROM (VALUES
        (1, 'Nurse'),
        (2, 'Nurse'),
        (3, 'Nurse'),
        (4, 'Physician'),
        (5, 'Physician'),
        (6, 'Tech'),
        (7, 'EMS'),
        (8, 'Admin'),
        (9, 'Housekeeping'),
        (10,'Housekeeping')
    ) AS r(slot, role)
), FirstNames AS (
    SELECT * FROM (VALUES
        (1,N'Avery'),(2,N'Jordan'),(3,N'Riley'),(4,N'Casey'),(5,N'Morgan'),
        (6,N'Quinn'),(7,N'Reese'),(8,N'Skylar'),(9,N'Drew'),(10,N'Sage'),
        (11,N'Rowan'),(12,N'Emerson'),(13,N'Harper'),(14,N'Kai'),(15,N'Sasha')
    ) AS f(idx, first)
), LastNames AS (
    SELECT * FROM (VALUES
        (1,N'Patel'),(2,N'Nguyen'),(3,N'Garcia'),(4,N'Cohen'),(5,N'Singh'),
        (6,N'Khan'),(7,N'Smith'),(8,N'Brooks'),(9,N'Tanaka'),(10,N'Romero'),
        (11,N'Park'),(12,N'Hassan'),(13,N'Lopez'),(14,N'Lee'),(15,N'Schmidt')
    ) AS l(idx, last)
)
INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate)
SELECT
    'S-' + RIGHT('000' + CAST(h.idx AS VARCHAR(3)), 3) + RIGHT('00' + CAST(r.slot AS VARCHAR(2)), 2),
    h.hospitalId,
    fn.first + N' ' + ln.last,
    r.role,
    CASE ((h.idx + r.slot) % 3)
        WHEN 0 THEN 'Day'
        WHEN 1 THEN 'Night'
        ELSE        'Swing'
    END,
    CAST(CASE WHEN ((h.idx * r.slot) % 7) = 0 THEN 1 ELSE 0 END AS BIT),
    DATEADD(DAY, -((h.idx * 13 + r.slot * 7) % 3500), CAST(GETDATE() AS DATE))
FROM (
    SELECT hospitalId,
           CAST(SUBSTRING(hospitalId, 3, 8) AS INT) AS idx
    FROM dbo.Hospitals
) h
CROSS JOIN Roles r
INNER JOIN FirstNames fn ON fn.idx = ((h.idx + r.slot) % 15) + 1
INNER JOIN LastNames  ln ON ln.idx = ((h.idx * 3 + r.slot * 2) % 15) + 1;
GO

-- ---- 7. Enable Change Tracking (required for Fabric Mirroring) ----
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_databases
    WHERE database_id = DB_ID()
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'ALTER DATABASE [' + DB_NAME() + N']
        SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 1 DAYS, AUTO_CLEANUP = ON);';
    EXEC (@sql);
END;

ALTER TABLE dbo.Hospitals ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
ALTER TABLE dbo.Wards     ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
ALTER TABLE dbo.Staff     ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
GO

-- ---- 8. Sanity counts ----
SELECT 'Hospitals' AS [table], COUNT(*) AS [rows] FROM dbo.Hospitals
UNION ALL SELECT 'Wards',      COUNT(*) FROM dbo.Wards
UNION ALL SELECT 'Staff',      COUNT(*) FROM dbo.Staff;
