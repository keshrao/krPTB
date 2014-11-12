function photoOn = checkPhotoOn(ai)
onThresh = 150;
data = [];
photoOn = 0;
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

if data(end,4)> onThresh
    photoOn = 1;
end
