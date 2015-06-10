function photo = checkPhotoOff(ai)
offThresh = .150;
data = [];

tic
while isempty(data)
    data = peekdata(ai,1);
    timelapse = toc;
    if(timelapse > 0.002)
        data(end,4) = 0;
        break;
    end
end
flushdata(ai);

photo = 1;
if data(end,4)< offThresh
    photo = 0;
end
