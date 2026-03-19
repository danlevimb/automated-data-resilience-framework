USE [DBAFramework];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [cfg].[usp_BackupDatabase]
    @DatabaseName           SYSNAME,
    @BackupType             VARCHAR(10),        -- FULL/DIFF/LOG
    @TierID                 TINYINT = NULL,
    @PathType               VARCHAR(30) = 'PRIMARY',
    @UseMirrorToSecondary   BIT = 1,        -- Enterprise default ON (writes to PRIMARY + SECONDARY)
    @WithVerify             BIT = 0,        -- OPTIONAL, USE CAREFULLY (COSTS TIME)
    @CopyOnly               BIT = 0,
    @WithChecksum           BIT = 1,
    @WithCompression        BIT = 1,
    @StatsPercent           TINYINT = 10,
    @CorrelationID          UNIQUEIDENTIFIER = NULL
AS
/*==============================================================================
  Procedure : cfg.usp_BackupDatabase
  Project   : Automated Backup & Recovery Framework
  Author    : Dan Levi Menchaca Bedolla
  Role      : SQL Server DBA / Data Infrastructure & Reliability Engineering
  Created   : 2026
  Component : Backup Execution Engine
  
  Purpose   :
      Executes policy-driven SQL Server backup operations for a single database,
      supporting FULL, DIFF, and LOG backup types with standardized storage
      routing, validation options, and telemetry capture.

      The procedure:
      - Resolves backup destination paths
      - Executes FULL / DIFF / LOG backups
      - Supports optional mirrored backup destinations
      - Applies compression and checksum options
      - Optionally performs RESTORE VERIFYONLY validation
      - Persists execution results into backup telemetry tables

  Inputs    :
      @DatabaseName
      @BackupType
      @TierID
      @PathType
      @UseMirrorToSecondary
      @WithVerify
      @CopyOnly
      @WithChecksum
      @WithCompression
      @StatsPercent
      @CorrelationID

  Outputs   :
      - Backup file(s) written to PRIMARY and optionally SECONDARY storage
      - Execution telemetry persisted into [dbo].[BackupRun]
      - Validation outcome when VERIFYONLY is requested

  Dependencies :
      cfg.DatabasePolicy
      dbo.BackupRun
      SQL Server BACKUP / RESTORE VERIFYONLY commands

  Used By   :
      cfg.usp_BackupByTierAndType
      SQL Server Agent backup jobs

  Notes     :
      This procedure is part of the backup layer of the framework.
      It standardizes backup execution and provides the telemetry foundation
      required by downstream restore validation workflows.
==============================================================================*/
BEGIN
    -------------------------------------------------------------------------
    -- INPUT VARIABLES (FOR DEBUG-MODE DE-COMENTARIZE)
    ---------------------------------------------------------------------------
    --DECLARE 
    --    @DatabaseName           SYSNAME = 'TestCDC',
    --    @BackupType             VARCHAR(10) = 'LOG',
    --    @TierID                 TINYINT = 2,
    --    @PathType               VARCHAR(30) = 'PRIMARY',
    --    @UseMirrorToSecondary   BIT = 1,
    --    @WithVerify             BIT = 1,
    --    @CopyOnly               BIT = 0,
    --    @WithChecksum           BIT = 0,
    --    @WithCompression        BIT = 0,
    --    @StatsPercent           TINYINT = 10,
    --    @CorrelationID          UNIQUEIDENTIFIER = NULL;

    SET NOCOUNT ON;
    -------------------------------------------------------------------------
    -- NORMALIZE INPUT-DATA
    -------------------------------------------------------------------------
    SET @BackupType = UPPER(LTRIM(RTRIM(@BackupType)));        
    -------------------------------------------------------------------------
    -- PRIOR-VALIDATIONS
    -------------------------------------------------------------------------        
    IF @BackupType NOT IN ('FULL','DIFF','LOG') THROW 50002, 'Invalid @BackupType. Use FULL, DIFF, or LOG.', 1;

    IF @DatabaseName = 'tempdb' THROW 50003, 'tempdb cannot be backed up.', 1;
   
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName) THROW 50004, 'Database not found.', 1;

    IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName AND state_desc <> 'ONLINE') THROW 50005, 'Database is not ONLINE. Backup skipped.', 1;

    IF @BackupType = 'LOG' AND (SELECT recovery_model_desc FROM sys.databases WHERE name = @DatabaseName) = 'SIMPLE' THROW 50006, 'LOG backup requested but database is in SIMPLE recovery model.', 1;

    /* LOCAL VARIABLES */
    DECLARE
        @RunID          BIGINT,
        @PrimaryBase    NVARCHAR(260),
        @SecondaryBase  NVARCHAR(260),
        @Ext            NVARCHAR(10),
        @Now            DATETIME2 = SYSDATETIME(),
        @Stamp          NVARCHAR(40),
        @PrimaryFile    NVARCHAR(4000),
        @SecondaryFile  NVARCHAR(4000),
        @Sql            NVARCHAR(MAX);
    -------------------------------------------------------------------------
    -- BUILD FILE PATHS & NAMES
    -------------------------------------------------------------------------    
    EXEC cfg.usp_GetActiveBasePath @PathType = 'PRIMARY', @BasePath = @PrimaryBase OUTPUT;

    IF @UseMirrorToSecondary = 1 EXEC cfg.usp_GetActiveBasePath @PathType = 'SECONDARY', @BasePath = @SecondaryBase OUTPUT;
 
    SET @Stamp = REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(30), SYSDATETIME(), 121), '-', ''), ':', ''), ' ', '_');
    
    SELECT 
        @Stamp = REPLACE(@Stamp, '.', ''),
        @Ext = CASE WHEN @BackupType = 'LOG' THEN '.trn' ELSE '.bak' END;

    SELECT  
        @PrimaryFile  = @PrimaryBase  + @DatabaseName + '_' + @BackupType + '_' + @Stamp + @Ext,
        @SecondaryFile= CASE WHEN @UseMirrorToSecondary = 1 
                        THEN @SecondaryBase + @DatabaseName + '_' + @BackupType + '_' + @Stamp + @Ext
                        ELSE NULL END;
    -------------------------------------------------------------------------
    -- CREATE LOG ROW
    -------------------------------------------------------------------------
    INSERT INTO log.BackupRun (   
        CorrelationID, DatabaseName, BackupType, TierID,
        PathType, PrimaryFile, SecondaryFile, UsedMirror,
        WithChecksum, WithCompression, IsCopyOnly, VerifyRequested)
    VALUES (
        @CorrelationID, @DatabaseName, @BackupType, @TierID,
        @PathType, @PrimaryFile, @SecondaryFile, @UseMirrorToSecondary,
        @WithChecksum, @WithCompression, @CopyOnly,
        @WithVerify);

    SET @RunID = SCOPE_IDENTITY();
    -------------------------------------------------------------------------
    -- BUILD TSQL COMMAND & EXECUTE
    -------------------------------------------------------------------------
    BEGIN TRY        
        SET @Sql = 
            N'BACKUP ' +
            CASE WHEN @BackupType = 'LOG' THEN N'LOG ' ELSE N'DATABASE ' END +
            QUOTENAME(@DatabaseName) +
            CASE WHEN @BackupType = 'DIFF' THEN N' TO DISK = N''' + REPLACE(@PrimaryFile,'''','''''') + N''''
                ELSE N' TO DISK = N''' + REPLACE(@PrimaryFile,'''','''''') + N''''
            END;

        IF @UseMirrorToSecondary = 1 SET @Sql += N' MIRROR TO DISK = N''' + REPLACE(@SecondaryFile,'''','''''') + N'''';

        SET @Sql += N' WITH ' +
            CASE WHEN @BackupType = 'DIFF' THEN N'DIFFERENTIAL, ' ELSE N'' END +
            CASE WHEN @CopyOnly = 1 AND @BackupType = 'FULL' THEN N'COPY_ONLY, ' ELSE N'' END +
            CASE WHEN @WithChecksum = 1 THEN N'CHECKSUM, ' ELSE N'' END +
            CASE WHEN @WithCompression = 1 THEN N'COMPRESSION, ' ELSE N'' END +
            CASE WHEN @UseMirrorToSecondary = 1 THEN N'FORMAT, ' ELSE N'INIT, ' END +
            N'INIT, STATS = ' + CAST(@StatsPercent AS NVARCHAR(10)) + N';';                       

         EXEC sys.sp_executesql @Sql;

        ;WITH b AS (   
            SELECT TOP (1) bs.backup_size, bs.compressed_backup_size
            FROM msdb.dbo.backupset bs
            WHERE bs.database_name = @DatabaseName
                AND bs.type = CASE @BackupType 
                                WHEN 'FULL' THEN 'D' 
                                WHEN 'DIFF' THEN 'I' 
                                WHEN 'LOG'  THEN 'L' 
                              END
                AND bs.backup_finish_date >= DATEADD(MINUTE, -10, @Now)
            ORDER BY bs.backup_finish_date DESC)
        UPDATE log.BackupRun
        SET BackupSizeBytes = b.backup_size,
            CompressedSizeBytes = b.compressed_backup_size
        FROM log.BackupRun r
        CROSS APPLY b
        WHERE r.BackupRunID = @RunID;

        IF @WithVerify = 1
            BEGIN
                SET @Sql =
                    N'RESTORE VERIFYONLY FROM DISK = N''' + REPLACE(@PrimaryFile,'''','''''') + N''' ' +
                    CASE WHEN @WithChecksum = 1 THEN N'WITH CHECKSUM;' ELSE N';' END;
                
                EXEC sys.sp_executesql @Sql;

                UPDATE log.BackupRun SET VerifySucceeded = 1 WHERE BackupRunID = @RunID;
            END;
        -------------------------------------------------------------------------
        -- UPDATE LOG ROW - SUCCESSFULL
        -------------------------------------------------------------------------
        UPDATE log.BackupRun SET EndedAt = SYSDATETIME(), Succeeded = 1 WHERE BackupRunID = @RunID;
    END TRY
    BEGIN CATCH
        -------------------------------------------------------------------------
        -- UPDATE LOG ROW - FAILED
        -------------------------------------------------------------------------
        UPDATE log.BackupRun
        SET EndedAt = SYSDATETIME(),
            Succeeded = 0,
            VerifySucceeded = CASE WHEN VerifyRequested = 1 THEN 0 ELSE VerifySucceeded END,
            ErrorNumber = ERROR_NUMBER(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE BackupRunID = @RunID;
        THROW;
    END CATCH;
END;
