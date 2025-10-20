USE [master]
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

IF OBJECT_ID(N'dbo.sp_ConvertQuery2HTMLTable', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_ConvertQuery2HTMLTable
    IF OBJECT_ID(N'dbo.sp_ConvertQuery2HTMLTable') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.sp_ConvertQuery2HTMLTable >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.sp_ConvertQuery2HTMLTable >>>'
END
GO

/*************************************************************************************
    SP Name:       sp_ConvertQuery2HTMLTable

    Description:
		Original Source: https://www.mssqltips.com/sqlservertip/5025/stored-procedure-to-generate-html-tables-for-sql-server-query-output/
		Alterations:
			Tim Cartwright:
                - https://gist.github.com/tcartwright/a38ecd0f8f8967c0eac5d3e691d4290b
				- Altered so that column headers are also output
				- Added minimal styling to table. Avoided use of css as most mail readers strip that out.
				- converted to system stored proc
				- cleaned up code around columnslist slightly


    Parameters:
        @SQLQuery - Query Text


    Example:
        EXEC dbo.sp_ConvertQuery2HTMLTable
                @SQLQuery = 'SELECT TOP 10 emp_id, emp_display_name FROM DBShrpn.dbo.employee'


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   10/08/2025  CJP                     - Created procedure

************************************************************************************/

CREATE PROCEDURE dbo.sp_ConvertQuery2HTMLTable
    (
        @SQLQuery NVARCHAR(MAX)
    )
AS
BEGIN

	DECLARE @headerslist NVARCHAR (4000) = ''
		, @columnslist NVARCHAR (4000) = ''
		, @restOfQuery NVARCHAR (4000) = ''
		, @DynTSQL NVARCHAR (4000)
		, @FromPos INT
		, @crlf CHAR(2) = CHAR(13) + CHAR(10)

	SELECT @columnslist += CONCAT(', ISNULL ([', NAME, '], '' '') AS [TD]'),
		@headerslist += CONCAT('<TH>', NAME, '</TH>')
	FROM sys.dm_exec_describe_first_result_set(@SQLQuery, NULL, 0)

	SET @FromPos = CHARINDEX ('FROM', @SQLQuery, 1)
	SET @restOfQuery = SUBSTRING(@SQLQuery, @FromPos, LEN(@SQLQuery) - @FromPos + 1)

	SET @DynTSQL = CONCAT ('SELECT REPLACE(CONCAT(''<TABLE border="1" cellspacing="0" cellpadding="1" align="left">',
			@crlf, '<THEAD>', @crlf, '<TR>', @headerslist, '</TR></THEAD>', @crlf, '<TBODY>', @crlf, ''', ', @crlf,
			'(CAST((SELECT (SELECT '
			, STUFF(@columnslist, 1, 2, ''), @crlf ,' '
			, @restOfQuery, @crlf
			,' FOR XML RAW (''TR''), TYPE, ELEMENTS)) AS NVARCHAR(MAX)))', @crlf
			,',''</TBODY></TABLE>''), ''</TR>'', ''</TR>'' + CHAR(13) + CHAR(10)) AS [html_table]')
	PRINT @DynTSQL
	EXEC (@DynTSQL)
END
GO

-- Make stored procedure
EXEC sys.[sp_MS_marksystemobject] @objname = N'dbo.sp_ConvertQuery2HTMLTable'
GO

GRANT EXECUTE TO PUBLIC
GO

IF OBJECT_ID(N'dbo.sp_ConvertQuery2HTMLTable', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.sp_ConvertQuery2HTMLTable >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.sp_ConvertQuery2HTMLTable >>>'
GO
