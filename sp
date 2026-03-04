CREATE OR ALTER PROCEDURE dbo.usp_GenerateJobInsertScript
(
    @JobIds NVARCHAR(MAX)   -- Example: '1001,1002,1005'
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Header
    PRINT 'SET IDENTITY_INSERT YourTableName ON;';
    PRINT 'GO';

    SELECT 
    'INSERT INTO YourTableName (JobId, Name, Amount, CreatedDate) VALUES (' +
    
    -- Identity column
    CAST(t.JobId AS VARCHAR(20)) + ',' +

    -- Name (string)
    CASE 
        WHEN t.Name IS NULL THEN 'NULL'
        ELSE '''' + REPLACE(t.Name, '''', '''''') + ''''
    END + ',' +

    -- Amount (numeric)
    CASE 
        WHEN t.Amount IS NULL THEN 'NULL'
        ELSE CAST(t.Amount AS VARCHAR(50))
    END + ',' +

    -- CreatedDate (datetime)
    CASE 
        WHEN t.CreatedDate IS NULL THEN 'NULL'
        ELSE '''' + CONVERT(VARCHAR(23), t.CreatedDate, 121) + ''''
    END +

    ');'
    
    FROM YourTableName t
    INNER JOIN STRING_SPLIT(@JobIds, ',') s
        ON t.JobId = TRY_CAST(s.value AS INT);

    PRINT 'GO';
    PRINT 'SET IDENTITY_INSERT YourTableName OFF;';
    PRINT 'GO';
END
GO
