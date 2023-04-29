# SQL_statistics_procedures
Some handy TSQL stored procedures which can be used (or adapted) to generate statistics. I'll keep updating the repo if more scripts are made which i generally use and which are generalizable (to some extent). Sometimes it is usefull to just run simple statistics in your TSQL database directly without the need to link and share data with a Python or R environment.

Current contents:
- OLS Procedure
A procedure which i use which can run an OLS regression within TSQL directly on any variables. Indeed it uses dynamic SQL for this, which is has to since table and column names need to be passed to the procedure to execute properly

- Network search
A procedure to analyze/view network connections in case you have a nodes and edges table set up. Using recursive search (WITH statements) this can be done in TSQL
