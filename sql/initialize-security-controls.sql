/*
  Do not run this during the code-only checkpoint.

  When the private Azure SQL Database is deployed and a Microsoft Entra admin is
  connected through an approved private path, replace <BACKEND_APP_NAME> with the
  exact App Service name output by infra/backend.bicep.
*/

CREATE TABLE dbo.SecurityControl (
  Id INT NOT NULL CONSTRAINT PK_SecurityControl PRIMARY KEY,
  Name NVARCHAR(120) NOT NULL,
  CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_SecurityControl_CreatedAt DEFAULT SYSUTCDATETIME()
);
GO

INSERT INTO dbo.SecurityControl (Id, Name)
VALUES
  (1, N'Network segmentation'),
  (2, N'Least-privilege access'),
  (3, N'Threat detection');
GO

CREATE USER [<BACKEND_APP_NAME>] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [<BACKEND_APP_NAME>];
GO
