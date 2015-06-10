function photo = krCheckPhoto(ai)
thresh = 2;
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

if data(end,4) > thresh
    photo = 1;
else
    photo = 0;
end
