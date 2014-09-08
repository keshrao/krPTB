function [ai, dio] = krConnectDAQ()

% connection to daq
ai = analoginput('mcc');
ai.SampleRate = 200000;
addchannel(ai,0); % eyeh
addchannel(ai,1); % eyev
addchannel(ai,2); % triggers from 1401 - spike times
addchannel(ai,3); % blank channel bc # chans must be even
ai.SamplesPerTrigger = 1;

% output connections
dio = digitalio('mcc');
addline(dio, 0, 'out'); % reward line
addline(dio, 2, 'out'); % trial triggers