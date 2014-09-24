% this program will help analyze the dir 

clear, clc


targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S30*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

