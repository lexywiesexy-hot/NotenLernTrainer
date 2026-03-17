@echo off
setlocal EnableExtensions DisableDelayedExpansion

if "%~1"=="" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage

set "COMMIT_MSG=%~1"
shift

set "START_DIR=%cd%"
set "SCRIPT_DIR=%~dp0"
set "REPO="
set "BRANCH="
set "UPSTREAM="
set "REMOTE="
set "REMOTE_BRANCH="

call :detect_repo "%START_DIR%"
if errorlevel 1 call :detect_repo "%SCRIPT_DIR%"
if errorlevel 1 (
    echo Could not find a Git repository from:
    echo   %START_DIR%
    echo   %SCRIPT_DIR%
    exit /b 1
)

call :enter_repo
if errorlevel 1 (
    echo Could not enter repository:
    echo   %REPO%
    exit /b 1
)

call :read_branch
if not defined BRANCH (
    echo Could not determine the current branch.
    popd
    exit /b 1
)

call :read_upstream

if defined UPSTREAM (
    for /f "tokens=1,* delims=/" %%A in ("%UPSTREAM%") do (
        set "REMOTE=%%A"
        set "REMOTE_BRANCH=%%B"
    )
) else (
    set "REMOTE=origin"
    set "REMOTE_BRANCH=%BRANCH%"
)

if "%~1"=="" goto :stage_all

echo Staging selected path(s)...
goto :stage_selected

:stage_all
echo Staging all changes in:
echo   %REPO%
call :run_git add -A
if errorlevel 1 goto :git_failed
goto :after_stage

:stage_selected
if "%~1"=="" goto :after_stage
call :run_git add -- "%~1"
if errorlevel 1 goto :git_failed
shift
goto :stage_selected

:after_stage
call :run_git diff --cached --quiet
if errorlevel 2 goto :git_failed
if errorlevel 1 (
    echo Creating commit...
    call :run_git commit -m "%COMMIT_MSG%"
    if errorlevel 1 goto :git_failed
) else (
    echo Nothing staged for commit. Skipping commit.
)

if defined UPSTREAM (
    echo Pulling latest changes from %UPSTREAM%...
    call :run_git pull --rebase
    if errorlevel 1 goto :git_failed

    echo Pushing %BRANCH%...
    call :run_git push
    if errorlevel 1 goto :git_failed
) else (
    echo No upstream configured for %BRANCH%.
    echo Pushing to %REMOTE% and setting upstream...
    call :run_git push -u "%REMOTE%" "%BRANCH%"
    if errorlevel 1 goto :git_failed
)

echo.
echo Push complete for %BRANCH%.
popd
exit /b 0

:detect_repo
set "REPO="
if exist "%~1\.git\" (
    for %%I in ("%~1") do set "REPO=%%~fI"
    exit /b 0
)
pushd "%~1" >nul 2>nul || exit /b 1
for /f "delims=" %%I in ('git -c safe.directory=* rev-parse --show-toplevel 2^>nul') do set "REPO=%%I"
popd
if defined REPO exit /b 0
exit /b 1

:enter_repo
pushd "%REPO%" >nul 2>nul || exit /b 1
exit /b 0

:read_branch
set "BRANCH="
set "BRANCH_FILE=%TEMP%\gitpushlatest-branch-%RANDOM%-%RANDOM%.txt"
git -c safe.directory=* symbolic-ref --quiet --short HEAD > "%BRANCH_FILE%" 2>nul
if exist "%BRANCH_FILE%" set /p BRANCH=<"%BRANCH_FILE%"
if exist "%BRANCH_FILE%" del "%BRANCH_FILE%" >nul 2>nul
if /I "%BRANCH%"=="HEAD" set "BRANCH="
exit /b 0

:read_upstream
set "UPSTREAM="
set "UPSTREAM_FILE=%TEMP%\gitpushlatest-upstream-%RANDOM%-%RANDOM%.txt"
git -c safe.directory=* rev-parse --abbrev-ref --symbolic-full-name @{u} > "%UPSTREAM_FILE%" 2>nul
if exist "%UPSTREAM_FILE%" set /p UPSTREAM=<"%UPSTREAM_FILE%"
if exist "%UPSTREAM_FILE%" del "%UPSTREAM_FILE%" >nul 2>nul
exit /b 0

:run_git
git -c safe.directory=* -C "%REPO%" %*
exit /b %errorlevel%

:git_failed
echo.
echo Git command failed. Fix the issue above and run the script again.
popd
exit /b 1

:usage
echo Usage:
echo   %~nx0 "Commit message"
echo   %~nx0 "Commit message" file1 [file2 ...]
echo.
echo Examples:
echo   %~nx0 "Improve mobile layout and staff focus" notenlerntrainer.html
echo   %~nx0 "WIP checkpoint"
exit /b 1
