
%% do pid control for thermal simulation
clear all
close all
delete(instrfind)
try
    stop(thermalCam)
catch
end
imaqreset
daqreset

load('C:\thermal_data\diffInds.mat')

metaData.increase_Kp = .4; % proportion error constant
metaData.increase_Ki = .3; % integral error constant
metaData.increase_Kd = .3; % derivative error constant
metaData.decrease_Kp = 0;
metaData.decrease_Ki = 0;
metaData.decrease_Kd = 0;
metaData.setTemps = [25 32 34 35 34 37 38];
metaData.thermROI = [37:69,148:177]; 
metaData.thermCalc = [.0051 -75.5];
metaData.time = datestr(now, 'yyyyddmmHHMMSS');
metaData.fileName = [metaData.time '_thermImgData'];
metaData.date = datestr(now, 'yyyy-mm-dd');

cd('C:\thermal_data\')
mkdir(metaData.date)
cd(['C:\thermal_data\' metaData.date])
mkdir(metaData.fileName)
cd(metaData.fileName)
copyfile('C:\matlabroot\thermal_imaging\PID_control_phys.m', pwd)

% these variables need to be declared before experiment starts
trialNum    = 1;
preTrialNum = 1;
resetTrial = 0;
runGetInds = 0;
lastSetTemp = 24;

thermalCam = videoinput('gige');
isStarted = 0;
daqObj = daq.createSession('ni');
daqObj.addAnalogInputChannel('Dev1', [0], 'Voltage');
daqObj.addDigitalChannel('Dev1', 'Port1/Line0:2', 'InputOnly' );
daqObj.addAnalogOutputChannel('Dev1', [0:1], 'Voltage');

tempData.count        = 1;
tempData.measuredTemp = nan(1,300*50);
tempData.timeStamp    = nan(1,300*50);
tempData.dTime        = nan(1,300*50);
tempData.setPoint     = nan(1,300*50);  
tempData.error        = nan(1,300*50);  
tempData.derivative   = nan(1,300*50);
tempData.integral     = nan(1,300*50);
tempData.output       = nan(300*50,2);  

daqOut = daqObj.inputSingleScan;
digital_0 = daqOut(2);
digital_1 = daqOut(3);
digital_2 = daqOut(4);

%% pause until primary matlab is ready
disp('waiting')
while digital_0 == 0

    daqObj.outputSingleScan([-4.99 0])
    daqOut = daqObj.inputSingleScan;
    digital_0 = daqOut(2);
    digital_1 = daqOut(3);
    digital_2 = daqOut(4);
    daqOut
    pause(.01)
end

disp('go')
%% while experiment is running
startTime = tic;
while digital_0 == 1
    
    daqOut = daqObj.inputSingleScan;
    digital_0 = daqOut(2);
    digital_1 = daqOut(3);
    digital_2 = daqOut(4);
    
    while digital_1 == 1
    
     if digital_2 == 0 && runGetInds == 0
         selectFlyThermalInds(thermalCam);
         pause(.1)
         load('C:\thermal_data\diffInds.mat')
         runGetInds = 1;
     end   
        
        
     if isStarted == 0
        start(thermalCam)
        isStarted = 1;
     end
     

     
        daqOut = daqObj.inputSingleScan;
        setTempIdx   = round(daqOut(1));
        if setTempIdx < 1
            setTempIdx = 1;
        end
        
        digital_0 = daqOut(2);
        digital_1 = daqOut(3);
        digital_2 = daqOut(4);
        
%         try
%             thermalFrame = getsnapshot(thermalCam);
%             roiFrame     = thermalFrame(30:91,120:200);
%             temps_C      = (roiFrame*metaData.thermCalc(1)) + metaData.thermCalc(2);
%         catch
%             pause(.01)
%             thermalFrame = getsnapshot(thermalCam);
%             roiFrame     = thermalFrame(30:91,120:200);
%             temps_C      = (roiFrame*metaData.thermCalc(1)) + metaData.thermCalc(2);
%         end
%         measuredTemp = max(temps_C(:));
%         
        thermalFrame = getsnapshot(thermalCam);
        temps_C      = (thermalFrame*metaData.thermCalc(1)) + metaData.thermCalc(2);
        sortedTemps  = flipud(sort((double(temps_C(diffInds)))));
        hotThird     = sortedTemps(1:ceil(numDiffInds*.3));
        measuredTemp = mean(hotThird);
       
        
        setPoint     = metaData.setTemps(setTempIdx);        
        currentError = setPoint - measuredTemp;
        
        tempData.measuredTemp(tempData.count) = measuredTemp;
        tempData.setPoint(tempData.count)     = setPoint;
        tempData.timeStamp(tempData.count)    = toc(startTime);
        tempData.error(tempData.count)        = currentError;
        
        if tempData.count < 2 
            tempData.dTime(1)        = 0;
            tempData.integral(1)     = 0;
            tempData.derivative(1)   = 0;
        else
            tempData.dTime(tempData.count)          = tempData.timeStamp(tempData.count)-tempData.timeStamp(tempData.count-1);
            tempData.derivative(tempData.count)     = (tempData.error(tempData.count)-tempData.error(tempData.count-1))/tempData.dTime(tempData.count);
            if tempData.setPoint(tempData.count)    ~= tempData.setPoint(tempData.count-1);
                tempData.integral(tempData.count)   = 0;
            else
                tempData.integral(tempData.count)   = tempData.integral(tempData.count-1) + (tempData.error(tempData.count)*tempData.dTime(tempData.count));
            end
        end
        
        if currentError > 0  
            output = (metaData.increase_Kp * tempData.error(tempData.count)) + (metaData.increase_Ki * tempData.integral(tempData.count))  + (metaData.increase_Kd * tempData.derivative(tempData.count));
        else
            output = (metaData.decrease_Kp * tempData.error(tempData.count)) + (metaData.decrease_Ki * tempData.integral(tempData.count))  + (metaData.decrease_Kd * tempData.derivative(tempData.count));
        end
        
        
        
        if tempData.setPoint(tempData.count) == metaData.setTemps(1)
                if currentError > 2
                    output = [-4.99 0]; %% if error positive, cool off!
                else
                    output = [-4.99 5];
                end      
        elseif tempData.setPoint(tempData.count) == metaData.setTemps(2)
            output = [-3.3 5];
        elseif  tempData.setPoint(tempData.count) > metaData.setTemps(2)...
                && tempData.setPoint(tempData.count) < metaData.setTemps(6)
            output = [-3.1 5];
        else
            output = [-2.8 5];
        end
       
        tempData.output(tempData.count,:) = output;
        daqObj.outputSingleScan([output])
        
        tempData.count = tempData.count+1;
    
        resetTrial = 1;
        pause(.005)
    end
    
    if resetTrial == 1
        stop(thermalCam)
        isStarted   = 0;
        runGetInds  = 0;
        
        lastSetTemp = tempData.setPoint(tempData.count-1);
        
        if digital_2 == 0
            save(['preTrial_0' num2str(preTrialNum)], 'tempData', 'metaData')
            preTrialNum = preTrialNum + 1;
        elseif trialNum < 10
            save(['tempTrial_0' num2str(trialNum)], 'tempData', 'metaData')
            trialNum = trialNum + 1;
        else
            save(['tempTrial_' num2str(trialNum)], 'tempData', 'metaData')
            trialNum = trialNum + 1;
        end
        
        close all
        
        f1 = figure;
        subplot(2,1,1)
        plot(tempData.timeStamp(1:tempData.count-1), tempData.measuredTemp(1:tempData.count-1), 'r')
        hold on
        plot(tempData.timeStamp(1:tempData.count-1), tempData.setPoint(1:tempData.count-1), 'b')
        ylim([20 40])
        ylabel('°C')
        title(['frame rate =' num2str( (tempData.count-1) / (tempData.timeStamp(tempData.count-1) - tempData.timeStamp(1)) ) 'Hz'])

        
        subplot(2,1,2)
        plot(tempData.timeStamp(1:tempData.count-1), tempData.output(1:tempData.count-1), 'r')
        ylim([-5 0])
        ylabel('output')
        xlabel('time (s)')
        
        %% re-set memory
        tempData.count        = 1;
        tempData.measuredTemp = nan(1,300*50);
        tempData.timeStamp    = nan(1,300*50);
        tempData.dTime        = nan(1,300*50);
        tempData.setPoint     = nan(1,300*50);  
        tempData.error        = nan(1,300*50);  
        tempData.derivative   = nan(1,300*50);
        tempData.integral     = nan(1,300*50);
        tempData.output       = nan(300*50,2);
        
        resetTrial = 0;
    end
    
    if lastSetTemp == metaData.setTemps(1)
        daqObj.outputSingleScan([-4.9 0])
    else
        daqObj.outputSingleScan([-3 5])
    end
    
end

daqObj.outputSingleScan([-4.99])
stop(thermalCam)

cd('C:\')
