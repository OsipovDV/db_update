USE master;
GO

ALTER DATABASE [$(DBNEWNAME)]
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

restore database [$(DBNEWNAME)]
from disk = '\\ra-sql04\Backup\$(DBNAME).bak'
with replace
GO

USE [$(DBNEWNAME)]
CREATE USER dev1c FOR LOGIN [dev1c];
GO

EXEC sp_addrolemember 'db_owner', 'dev1c'
GO

ALTER DATABASE [$(DBNEWNAME)] SET RECOVERY SIMPLE;
GO

DBCC SHRINKFILE(2,2)
GO

ALTER DATABASE [$(DBNEWNAME)] SET MULTI_USER
GO

USE [msdb]
go