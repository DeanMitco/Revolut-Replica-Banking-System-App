-- Local bootstrap only. Service-specific schema changes belong in EF migrations.
-- GO separates CREATE DATABASE into its own batch, outside a transaction.
USE [master];
GO

IF DB_ID(N'RevolutReplica.Identity') IS NULL
    CREATE DATABASE [RevolutReplica.Identity];
GO

IF DB_ID(N'RevolutReplica.Accounts') IS NULL
    CREATE DATABASE [RevolutReplica.Accounts];
GO

IF DB_ID(N'RevolutReplica.Fx') IS NULL
    CREATE DATABASE [RevolutReplica.Fx];
GO

IF DB_ID(N'RevolutReplica.FraudAudit') IS NULL
    CREATE DATABASE [RevolutReplica.FraudAudit];
GO

IF DB_ID(N'RevolutReplica.Notifications') IS NULL
    CREATE DATABASE [RevolutReplica.Notifications];
GO
