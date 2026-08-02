@echo off
call C:\Tools\oss-cad-suite\environment.bat
cd /d "%~dp0"
python run_tests.py %*
