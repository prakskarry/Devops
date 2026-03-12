IF OBJECT_ID('dbo.usp_GenerateJobScripts','P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GenerateJobScripts;
GO

CREATE PROCEDURE dbo.usp_GenerateJobScripts
(
    @JobDefinitionIds NVARCHAR(MAX)   -- Example: '1,2,5'
)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Parse input IDs
    ------------------------------------------------------------
    DECLARE @Ids TABLE (JOB_DEFINITION_ID INT PRIMARY KEY);

    INSERT INTO @Ids
    SELECT DISTINCT TRY_CAST(value AS INT)
    FROM STRING_SPLIT(@JobDefinitionIds, ',')
    WHERE TRY_CAST(value AS INT) IS NOT NULL;

    ------------------------------------------------------------
    -- JOB_DEFINITION SCRIPT
    ------------------------------------------------------------
    PRINT '/*==================================================';
    PRINT ' JOB_DEFINITION INSERT SCRIPT';
    PRINT '==================================================*/';
    PRINT 'SET IDENTITY_INSERT dbo.JOB_DEFINITION ON;';
    PRINT 'GO';

    DECLARE @JD_SCRIPT NVARCHAR(MAX) = '';

    SELECT @JD_SCRIPT = @JD_SCRIPT + CHAR(13)+CHAR(10) +
'
IF EXISTS (SELECT 1 FROM dbo.JOB_DEFINITION WHERE JOB_DEFINITION_ID = ' + 
CAST(jd.JOB_DEFINITION_ID AS VARCHAR(20)) + ')
BEGIN
    PRINT ''JOB_DEFINITION_ID ' + CAST(jd.JOB_DEFINITION_ID AS VARCHAR(20)) + ' already exists - skipping'';
END
ELSE
BEGIN
    INSERT INTO dbo.JOB_DEFINITION
    (JOB_DEFINITION_ID, job_name, job_command, WORKFLOW_TASK_NAME,
     ENABLED, SR_DEFINATION_NAME, BUSINESS_CALENDAR_ID,
     MODIFIED_BY, MODIFIED_DATE, EXPECTED_THRESHOLD,
     CREATE_DATE, CODE_VERSION_HANDLER)
    VALUES
    (' +

        CAST(jd.JOB_DEFINITION_ID AS VARCHAR(20)) + ',' +
        '''' + REPLACE(jd.job_name,'''','''''') + ''',' +
        '''' + REPLACE(jd.job_command,'''','''''') + ''',' +

        CASE WHEN jd.WORKFLOW_TASK_NAME IS NULL THEN 'NULL'
             ELSE '''' + REPLACE(jd.WORKFLOW_TASK_NAME,'''','''''') + ''''
        END + ',' +

        CASE WHEN jd.ENABLED IS NULL THEN 'NULL'
             ELSE CAST(jd.ENABLED AS VARCHAR)
        END + ',' +

        CASE WHEN jd.SR_DEFINATION_NAME IS NULL THEN 'NULL'
             ELSE '''' + REPLACE(jd.SR_DEFINATION_NAME,'''','''''') + ''''
        END + ',' +

        CASE WHEN jd.BUSINESS_CALENDAR_ID IS NULL THEN 'NULL'
             ELSE CAST(jd.BUSINESS_CALENDAR_ID AS VARCHAR)
        END + ',' +

        CASE WHEN jd.MODIFIED_BY IS NULL THEN 'NULL'
             ELSE '''' + REPLACE(jd.MODIFIED_BY,'''','''''') + ''''
        END + ',' +

        'GETDATE(),' +

        CASE WHEN jd.EXPECTED_THRESHOLD IS NULL THEN 'NULL'
             ELSE CAST(jd.EXPECTED_THRESHOLD AS VARCHAR)
        END + ',' +

        '''' + CONVERT(VARCHAR(23), jd.CREATE_DATE,121) + ''',' +

        CASE WHEN jd.CODE_VERSION_HANDLER IS NULL THEN 'NULL'
             ELSE '''' + REPLACE(jd.CODE_VERSION_HANDLER,'''','''''') + ''''
        END +

    ');
END
'
    FROM dbo.JOB_DEFINITION jd
    JOIN @Ids i
        ON jd.JOB_DEFINITION_ID = i.JOB_DEFINITION_ID;

    IF @JD_SCRIPT <> ''
        PRINT @JD_SCRIPT;

    PRINT 'GO';
    PRINT 'SET IDENTITY_INSERT dbo.JOB_DEFINITION OFF;';
    PRINT 'GO';
    PRINT '';

    ------------------------------------------------------------
    -- JOB_SCHEDULE SCRIPT
    ------------------------------------------------------------
    PRINT '/*==================================================';
    PRINT ' JOB_SCHEDULE INSERT SCRIPT';
    PRINT '==================================================*/';
    PRINT 'SET IDENTITY_INSERT dbo.JOB_SCHEDULE ON;';
    PRINT 'GO';

    DECLARE @JS_SCRIPT NVARCHAR(MAX) = '';

    SELECT @JS_SCRIPT = @JS_SCRIPT + CHAR(13)+CHAR(10) +
'
IF EXISTS (SELECT 1 FROM dbo.JOB_SCHEDULE WHERE JOB_SCHEDULE_ID = ' +
CAST(js.JOB_SCHEDULE_ID AS VARCHAR(20)) + ')
BEGIN
    PRINT ''JOB_SCHEDULE_ID ' + CAST(js.JOB_SCHEDULE_ID AS VARCHAR(20)) + ' already exists - skipping'';
END
ELSE
BEGIN
    INSERT INTO dbo.JOB_SCHEDULE
    (JOB_SCHEDULE_ID, JOB_DEFINITION_ID, SERVER_NAME,
     SCHEDULE_TYPE, SCHEDULE, INSTANCE_COUNT,
     ENABLED, MODFIED_BY, MODIFIED_DATE, CREATE_DATE)
    VALUES
    (' +

        CAST(js.JOB_SCHEDULE_ID AS VARCHAR(20)) + ',' +
        CAST(js.JOB_DEFINITION_ID AS VARCHAR(20)) + ',' +
        '''' + REPLACE(js.SERVER_NAME,'''','''''') + ''',' +
        '''' + REPLACE(js.SCHEDULE_TYPE,'''','''''') + ''',' +
        '''' + REPLACE(js.SCHEDULE,'''','''''') + ''',' +
        CAST(js.INSTANCE_COUNT AS VARCHAR) + ',' +

        CASE WHEN js.ENABLED IS NULL THEN 'NULL'
             ELSE CAST(js.ENABLED AS VARCHAR)
        END + ',' +

        CASE WHEN js.MODFIED_BY IS NULL THEN 'NULL'
             ELSE '''' + REPLACE(js.MODFIED_BY,'''','''''') + ''''
        END + ',' +

        'GETDATE(),GETDATE()' +

    ');
END
'
    FROM dbo.JOB_SCHEDULE js
    JOIN @Ids i
        ON js.JOB_DEFINITION_ID = i.JOB_DEFINITION_ID;

    IF @JS_SCRIPT <> ''
        PRINT @JS_SCRIPT;

    PRINT 'GO';
    PRINT 'SET IDENTITY_INSERT dbo.JOB_SCHEDULE OFF;';
    PRINT 'GO';

END
GO
