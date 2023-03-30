@echo off
start mame.exe vsavj -pluginspath %cd%\scripts\vsav_training -script %cd%\scripts\vsav_training\main.lua -debug
exit