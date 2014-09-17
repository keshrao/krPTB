function [ai, dio] = krConnectDAQ_trigtest()

% connection to daq
ai = analoginput('mcc');
addchannel(ai,0); % eyeh
addchannel(ai,1); % eyev
addchannel(ai,2); % spike triggers
addchannel(ai,3); % dummy channel

% output connections
dio = digitalio('mcc');
addline(dio, 0, 'out'); % reward line
addline(dio, 2, 'out'); % trial triggers