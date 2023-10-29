--restore db in standby mode to view data at a specified time
Restore a backup of the database, in STANDBY mode, alongside the live database 
Roll the logs forward to the point just before the bad transaction occurred, and data was lost. 
Copy the lost data across to the live database and drop the restored copy 


