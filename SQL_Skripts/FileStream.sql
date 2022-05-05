use [HockeyShop]

-- Remove FILESTREAM file and filegroup
ALTER Database HockeyShop REMOVE FILE HELIOS__HockeyShop__FileStreamFile
GO
ALTER Database HockeyShop REMOVE FILEGROUP HELIOS__HockeyShop__FileStreamGroup
GO
