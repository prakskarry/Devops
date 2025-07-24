SET NOCOUNT ON;

-- Temporary table to store results
IF OBJECT_ID('tempdb..#IndexInfo') IS NOT NULL DROP TABLE #IndexInfo;

CREATE TABLE #IndexInfo (
    DatabaseName SYSNAME,
    SchemaName SYSNAME,
    TableName SYSNAME,
    IndexName SYSNAME,
    IndexTypeDesc NVARCHAR(60),
    ColumnNames NVARCHAR(MAX)
);

DECLARE @DBName SYSNAME;
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE state_desc = 'ONLINE'
  AND name NOT IN ('master','tempdb','model','msdb');

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
    USE [' + @DBName + '];

    IF EXISTS (
        SELECT 1
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name = ''MESSAGE''
    )
    BEGIN
        INSERT INTO #IndexInfo (DatabaseName, SchemaName, TableName, IndexName, IndexTypeDesc, ColumnNames)
        SELECT 
            DB_NAME() AS DatabaseName,
            SCHEMA_NAME(t.schema_id) AS SchemaName,
            t.name AS TableName,
            i.name AS IndexName,
            i.type_desc AS IndexTypeDesc,
            STUFF((
                SELECT '', '' + c.name
                FROM sys.index_columns ic
                JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id 
                    AND ic.is_included_column = 0
                ORDER BY ic.key_ordinal
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),
                1, 2, '''') AS ColumnNames
        FROM sys.indexes i
        JOIN sys.tables t ON t.object_id = i.object_id
        WHERE t.name = ''MSG_P'' AND i.name IS NOT NULL;
    END;
    ';
    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Display results
SELECT * FROM #IndexInfo ORDER BY DatabaseName, SchemaName, IndexName;
