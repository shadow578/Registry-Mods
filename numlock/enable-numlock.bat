@echo off
powershell -ExecutionPolicy Unrestricted -Command "Set-Location '%~dp0'; & '.\enable-numlock.ps1'"
timeout 5