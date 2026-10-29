@echo off
cd /d "%~dp0web-app"
pip install -r requirements.txt
python app.py
