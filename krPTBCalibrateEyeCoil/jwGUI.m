clear all;

%% UI for Paradigms

% Create UI Window
win = figure(1);clf;

uicontrol('Parent',win,'Style','popup','String','cal|dir','Position',[20,300,100,100]);
uicontrol('Parent',win,'Style','pushbutton','String','Start','Position',[200,380,80,40]);
uicontrol('Parent',win,'Style','pushbutton','String','Calibrate','Position',[200,200,80,40],'Callback',@krClibrateEyeCoil);
%krCalibrateEyeCoil;