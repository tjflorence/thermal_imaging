function getFlyThermalInds(thermalCam, daqObj)
disp('acquiring fly thermal pixels')

framesToAcquire = 100;

metaData.thermCalc  = [.0051 -75.5];
thermalFrame        = getsnapshot(thermalCam);
sizeFrame           = size(thermalFrame);
temps_C             = double((thermalFrame*metaData.thermCalc(1)) + metaData.thermCalc(2));
testMat_off         = zeros(sizeFrame(1),sizeFrame(2));
testMat_on          = zeros(sizeFrame(1),sizeFrame(2));

daqObj.outputSingleScan([-4.99])

for aa = 1:framesToAcquire
    
   thermalFrame         = getsnapshot(thermalCam);
   temps_C              = double((thermalFrame*metaData.thermCalc(1)) + metaData.thermCalc(2));
   testMat_off          = temps_C + testMat_off;
    
end

daqObj.outputSingleScan([-2.5])
pause(10)

for aa = 1:framesToAcquire
    
   thermalFrame         = getsnapshot(thermalCam);
   temps_C              = double((thermalFrame*metaData.thermCalc(1)) + metaData.thermCalc(2));
   testMat_on           = temps_C + testMat_on;
    
end

daqObj.outputSingleScan([-4.99])

avgOff = (testMat_off)/framesToAcquire;
avgOn  = (testMat_on)/framesToAcquire;

diffMat = avgOn - avgOff;
diffInds = find(diffMat > 6);
numDiffInds = length(diffInds);

save('C:\thermal_data\diffInds', 'diffInds', 'numDiffInds')
disp('pixel indices acquired and saved')



