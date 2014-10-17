function [ai, dio] = krConnectDAQ()

% connection to daq
ai = analoginput('mcc');
ai.SampleRate = 1000000;
addchannel(ai,0); % eyeh
addchannel(ai,1); % eyev
ai.SamplesPerTrigger = 1;

% output connections
dio = digitalio('mcc');
addline(dio, 0, 'out'); % reward line
addline(dio, 2, 'out'); % trial triggers