function [eyePosX eyePosY] = krPeekEyePos(ai)

% this file is in krPlotEPos

data = [];
tic
while isempty(data)
    data = peekdata(ai,1);
    timelapse = toc;
    if(timelapse > 0.002)
        data(end,1) = 0;
        data(end,2) = 0;
        break;
    end
end
flushdata(ai);

eyePosX = data(end,1)*100;
eyePosY = data(end,2)*100;