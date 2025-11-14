REM Clean upload folder before run this new cycle.
Del    C:\FTP_DATA\DATA\DEV\Load\*.*   /Q

REM Preparing file for load: Interface file
Del     C:\FTP_DATA\DATA\DEV\Interface_SS_VENUS.txt
Del     C:\FTP_DATA\DATA\DEV\Load\Loaded\Interface_SS_VENUS.txt
Copy  C:\FTP_DATA\DATA\DEV\Interface_SS_VENUS*.txt 		C:\FTP_DATA\DATA\DEV\Load\History\Interface_SS_VENUS*.txt
Copy  C:\FTP_DATA\DATA\DEV\Interface_SS_VENUS*.txt 		C:\FTP_DATA\DATA\DEV\Load\Interface_SS_VENUS.txt
Del     C:\FTP_DATA\DATA\DEV\Interface_SS_VENUS*.txt


REM Preparing file for load: Interface file
Del     C:\FTP_DATA\DATA\DEV\Interface_SS_GANYMEDE.txt
Del     C:\FTP_DATA\DATA\DEV\Load\Loaded\Interface_SS_GANYMEDE.txt
Copy  C:\FTP_DATA\DATA\DEV\Interface_SS_GANYMEDE*.txt 	C:\FTP_DATA\DATA\DEV\Load\History\Interface_SS_GANYMEDE*.txt
Copy  C:\FTP_DATA\DATA\DEV\Interface_SS_GANYMEDE*.txt 	C:\FTP_DATA\DATA\DEV\Load\Interface_SS_GANYMEDE.txt
Del     C:\FTP_DATA\DATA\DEV\Interface_SS_GANYMEDE*.txt
