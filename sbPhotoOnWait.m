function sbPhotoOnWait(ai,abortTime)
startTime = tic;
isPhoto = krCheckPhoto(ai);
while ~isPhoto && toc(startTime) < abortTime
    isPhoto = krCheckPhoto(ai);
end