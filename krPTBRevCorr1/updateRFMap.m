function [frmat, frtrls] = updateRFMap(frmat, frtrls, randXpos, randYpos, numtrigs)

global xdiv

xdiv = 40;

xrng = [100 1000];
yrng = [50 700];

hbins = linspace(xrng(1), xrng(2), xdiv);
vbins = linspace(yrng(1), yrng(2), xdiv);


for i = 1:length(randXpos)
    row = find(hbins > randXpos(i), 1, 'first');
    col = find(vbins > randYpos(i), 1, 'first');
    
    frmat(row, col) = frmat(row, col) + numtrigs;
    frtrls(row,col) = frtrls(row, col) + 1;
end


%figure(3);
heatmap(frmat./frtrls); colorbar()
drawnow