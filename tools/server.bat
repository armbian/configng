@echo off
REM Check if python is installed
python --version
if errorlevel 1 (
    echo Python could not be found
    exit /b
)

REM Start the Python server on the first available port in the range 8000-8100
for /L %%i in (8000,1,8100) do (
    echo Starting server on port %%i...
    start /b python -m http.server %%i
    timeout /t 1
    REM Check if the server started successfully
    netstat -an | findstr /R /C:"^  TCP    0.0.0.0:%%i "
    if not errorlevel 1 (
        echo Server started on port %%i. Press any key to stop the server.
        pause
        echo Stopping server...
        taskkill /IM python.exe /F
        echo Server stopped.
        exit /b
    ) else (
        echo Failed to start server on port %%i
    )
)
