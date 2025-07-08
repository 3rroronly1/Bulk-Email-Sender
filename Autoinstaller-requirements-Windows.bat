@echo off
setlocal EnableDelayedExpansion

:: Script to automate setup of bulk-email-sender Laravel application on Windows 11
echo Setting up bulk-email-sender application on Windows 11...

:: Step 0: Check for administrative privileges
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo This script requires administrative privileges. Please run as Administrator.
    pause
    exit /b 1
)

:: Step 1: Check for Chocolatey and install if not present
echo Checking for Chocolatey...
where choco >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    if %ERRORLEVEL% neq 0 (
        echo Failed to install Chocolatey. Please install it manually and rerun the script.
        pause
        exit /b 1
    )
    :: Refresh environment variables
    call refreshenv
)

:: Step 2: Check and install PHP 8.1
echo Checking for PHP 8.1 or higher...
where php >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing PHP 8.1...
    choco install php --version=8.1.10 -y
    if %ERRORLEVEL% neq 0 (
        echo Failed to install PHP. Please install PHP 8.1 or higher manually.
        pause
        exit /b 1
    )
) else (
    for /f "tokens=2 delims= " %%i in ('php -v ^| findstr /C:"PHP 8."') do (
        set PHP_VERSION=%%i
    )
    if "!PHP_VERSION!"=="" (
        echo PHP version is not 8.1 or higher. Installing PHP 8.1...
        choco install php --version=8.1.10 -y
        if %ERRORLEVEL% neq 0 (
            echo Failed to install PHP. Please install PHP 8.1 or higher manually.
            pause
            exit /b 1
        )
    )
)

:: Step 3: Enable PHP extensions
echo Enabling required PHP extensions...
for %%e in (mbstring openssl pdo_mysql fileinfo zip xml) do (
    echo extension=%%e >> "%ProgramFiles%\php-8.1\php.ini"
)

:: Step 4: Check and install Composer
echo Checking for Composer...
where composer >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing Composer...
    choco install composer -y
    if %ERRORLEVEL% neq 0 (
        echo Failed to install Composer. Please install Composer manually.
        pause
        exit /b 1
    )
)

:: Step 5: Check and install MySQL
echo Checking for MySQL...
where mysql >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing MySQL...
    choco install mysql -y
    if %ERRORLEVEL% neq 0 (
        echo Failed to install MySQL. Please install MySQL manually.
        pause
        exit /b 1
    )
)

:: Step 6: Check and install Node.js
echo Checking for Node.js...
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing Node.js...
    choco install nodejs --version=16.13.0 -y
    if %ERRORLEVEL% neq 0 (
        echo Failed to install Node.js. Please install Node.js manually.
        pause
        exit /b 1
    )
)

:: Step 7: Check and install Git
echo Checking for Git...
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing Git...
    choco install git -y
    if %ERRORLEVEL% neq 0 (
        echo Failed to install Git. Please install Git manually.
        pause
        exit /b 1
    )
)

:: Step 8: Ensure MySQL service is running
echo Ensuring MySQL service is running...
net start mysql >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Starting MySQL service...
    net start mysql
    if %ERRORLEVEL% neq 0 (
        echo Failed to start MySQL service. Attempting to initialize MySQL...
        mysqld --initialize-insecure
        net start mysql
        if %ERRORLEVEL% neq 0 (
            echo Failed to start MySQL service. Please ensure MySQL is installed and configured correctly.
            pause
            exit /b 1
        )
    )
)

:: Step 9: Prompt for MySQL root password and database details
set MYSQL_ROOT_PASSWORD=
set /p MYSQL_ROOT_PASSWORD=Enter MySQL root password (leave blank for default/no password):
set /p DB_DATABASE=Enter database name for the application (e.g., bulk_email_sender):
set /p DB_USERNAME=Enter database username (e.g., root):
set /p DB_PASSWORD=Enter database password (leave blank for none):
set /p DB_HOST=Enter database host (e.g., 127.0.0.1):
set /p DB_PORT=Enter database port (e.g., 3306):
set /p MAIL_HOST=Enter your SMTP host (e.g., smtp.gmail.com):
set /p MAIL_PORT=Enter your SMTP port (e.g., 587):
set /p MAIL_USERNAME=Enter your SMTP username:
set /p MAIL_PASSWORD=Enter your SMTP password:
set /p MAIL_FROM_ADDRESS=Enter your from email address (e.g., your_email@example.com):
set /p MAIL_FROM_NAME=Enter your from name (e.g., Bulk Email Sender):

:: Step 10: Create database if it doesn't exist
echo Creating database %DB_DATABASE%...
if "!MYSQL_ROOT_PASSWORD!"=="" (
    mysql --user=%DB_USERNAME% --host=%DB_HOST% --port=%DB_PORT% -e "CREATE DATABASE IF NOT EXISTS %DB_DATABASE%;"
) else (
    mysql --user=%DB_USERNAME% --password=%MYSQL_ROOT_PASSWORD% --host=%DB_HOST% --port=%DB_PORT% -e "CREATE DATABASE IF NOT EXISTS %DB_DATABASE%;"
)
if %ERRORLEVEL% neq 0 (
    echo Failed to create database. Please check MySQL credentials and try again.
    pause
    exit /b 1
)

:: Step 11: Clone the repository
echo Cloning the repository...
if exist bulk-email-sender (
    echo Repository already exists. Pulling latest changes...
    cd bulk-email-sender
    git pull
    cd ..
) else (
    git clone https://github.com/arafat-web/bulk-email-sender.git
    if %ERRORLEVEL% neq 0 (
        echo Failed to clone repository. Please check your network or Git installation.
        pause
        exit /b 1
    )
)

cd bulk-email-sender

:: Step 12: Set directory permissions
echo Setting permissions for storage and cache directories...
icacls storage /grant "Everyone:(OI)(CI)F" /T
icacls bootstrap\cache /grant "Everyone:(OI)(CI)F" /T
if %ERRORLEVEL% neq 0 (
    echo Failed to set directory permissions. Please set write permissions for storage and bootstrap/cache manually.
    pause
    exit /b 1
)

:: Step 13: Install Composer dependencies
echo Installing Composer dependencies...
composer install
if %ERRORLEVEL% neq 0 (
    echo Failed to install Composer dependencies. Please run 'composer install' manually.
    pause
    exit /b 1
)

:: Step 14: Install npm dependencies and build frontend assets
echo Installing npm dependencies...
npm install
if %ERRORLEVEL% neq 0 (
    echo Failed to install npm dependencies. Please run 'npm install' manually.
    pause
    exit /b 1
)
echo Building frontend assets...
npm run build
if %ERRORLEVEL% neq 0 (
    echo Failed to build frontend assets. Please run 'npm run build' manually.
    pause
    exit /b 1
)

:: Step 15: Configure .env file
echo Configuring environment variables...
if not exist .env (
    copy .env.example .env
    if %ERRORLEVEL% neq 0 (
        echo Failed to copy .env.example to .env. Please copy it manually.
        pause
        exit /b 1
    )
)

:: Update .env file
echo Updating .env file...
(
echo APP_NAME=Laravel
echo APP_ENV=local
echo APP_KEY=
echo APP_DEBUG=true
echo APP_URL=http://localhost
echo.
echo LOG_CHANNEL=stack
echo LOG_DEPRECATIONS_CHANNEL=null
echo LOG_LEVEL=debug
echo.
echo DB_CONNECTION=mysql
echo DB_HOST=%DB_HOST%
echo DB_PORT=%DB_PORT%
echo DB_DATABASE=%DB_DATABASE%
echo DB_USERNAME=%DB_USERNAME%
echo DB_PASSWORD=%DB_PASSWORD%
echo.
echo BROADCAST_DRIVER=log
echo CACHE_DRIVER=file
echo FILESYSTEM_DISK=local
echo QUEUE_CONNECTION=sync
echo SESSION_DRIVER=file
echo SESSION_LIFETIME=120
echo.
echo MEMCACHED_HOST=127.0.0.1
echo.
echo REDIS_HOST=127.0.0.1
echo REDIS_PASSWORD=null
echo REDIS_PORT=6379
echo.
echo MAIL_MAILER=smtp
echo MAIL_HOST=%MAIL_HOST%
echo MAIL_PORT=%MAIL_PORT%
echo MAIL_USERNAME=%MAIL_USERNAME%
echo MAIL_PASSWORD=%MAIL_PASSWORD%
echo MAIL_ENCRYPTION=tls
echo MAIL_FROM_ADDRESS="%MAIL_FROM_ADDRESS%"
echo MAIL_FROM_NAME="%MAIL_FROM_NAME%"
echo.
echo AWS_ACCESS_KEY_ID=
echo AWS_SECRET_ACCESS_KEY=
echo AWS_DEFAULT_REGION=us-east-1
echo AWS_BUCKET=
echo AWS_USE_PATH_STYLE_ENDPOINT=false
echo.
echo PUSHER_APP_ID=
echo PUSHER_APP_KEY=
echo PUSHER_APP_SECRET=
echo PUSHER_HOST=
echo PUSHER_PORT=443
echo PUSHER_SCHEME=https
echo PUSHER_APP_CLUSTER=mt1
echo.
echo VITE_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
echo VITE_PUSHER_HOST="${PUSHER_HOST}"
echo VITE_PUSHER_PORT="${PUSHER_PORT}"
echo VITE_PUSHER_SCHEME="${PUSHER_SCHEME}"
echo VITE_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"
) > .env

:: Step 16: Generate application key
echo Generating application key...
php artisan key:generate
if %ERRORLEVEL% neq 0 (
    echo Failed to generate application key. Please run 'php artisan key:generate' manually.
    pause
    exit /b 1
)

:: Step 17: Run migrations and seed database
echo Running migrations and seeding database...
php artisan migrate --seed
if %ERRORLEVEL% neq 0 (
    echo Failed to run migrations. Please check your database configuration and run 'php artisan migrate --seed' manually.
    pause
    exit /b 1
)

:: Step 18: Add firewall rule for port 8000
echo Adding firewall rule for Laravel server (port 8000)...
netsh advfirewall firewall add rule name="Laravel Server" dir=in action=allow protocol=TCP localport=8000
if %ERRORLEVEL% neq 0 (
    echo Failed to add firewall rule. Please allow port 8000 manually in Windows Firewall.
)

:: Step 19: Start queue in a new window
echo Starting queue listener...
start cmd /k php artisan queue:listen

:: Step 20: Serve the application
echo Starting Laravel development server...
start cmd /k php artisan serve

:: Wait a moment for the server to start
timeout /t 5

echo.
echo Setup complete! Access the application at http://localhost:8000
echo Admin login:
echo Email: admin@email.com
echo Password: 12345678
echo.
echo Troubleshooting:
echo - If MySQL fails, check the service in 'services.msc' or ensure port 3306 is free.
echo - If Composer fails, run 'composer diagnose' in the project directory.
echo - If frontend assets fail, run 'npm install' and 'npm run build' manually.
echo - Ensure SMTP credentials are valid (e.g., use Gmail app-specific password).
echo.
pause

endlocal