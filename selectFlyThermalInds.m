function selectFlyThermalInds(thermalCam)
disp('time to label those pixels! woo WOO')
metaData.thermCalc = [.0051 -75.5];


thermalFrame        = getsnapshot(thermalCam);
sizeFrame           = size(thermalFrame);
temps_C             = double((thermalFrame*metaData.thermCalc(1)) + metaData.thermCalc(2));

imagesc(temps_C);
axis equal off
disp('select fly thermal pixel');
[xc, yc] = getpts(gca);


bgFrame = zeros(sizeFrame);
bgFrame(round(yc), round(xc)) = 1;

diffInds = find(bgFrame==1);
numDiffInds = length(diffInds);

save('C:\thermal_data\diffInds', 'diffInds', 'numDiffInds')
disp('pixel indices acquired and saved')



