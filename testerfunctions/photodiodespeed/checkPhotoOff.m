function photoOff = checkPhotoOff(ai)
offThresh = 150;
data = [];
photoOff = 0;
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

if data(end,4)< offThresh
    photoOff = 1;
end
