function [eyePosX eyePosY trigger] = krGetEyePosTrigger(ai)

% this file is in krPlotEPos

start(ai);
[d ~] = getdata(ai);
flushdata(ai);
stop(ai);

eyePosX = d(end,1)*100; % scaling from volts to deg
eyePosY = d(end,2)*100; % scaling from volts to deg
trigger = d(:,3); % triggering