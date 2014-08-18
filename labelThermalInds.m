function labelThermalInds(thermalCam)
disp('time to label those pixels! woo WOO')
metaData.thermCalc = [.0051 -75.5];


thermalFrame        = getsnapshot(thermalCam);
sizeFrame           = size(thermalFrame);
temps_C             = double((thermalFrame*metaData.thermCalc(1)) + metaData.thermCalc(2));

imagesc(temps_C);
axis equal off
disp('select ball center');
[xc, yc] = getpts(gca);

hold on
z1 = scatter(xc, yc, 100);
set(z1, 'MarkerEdgeColor', 'w', 'MarkerFaceColor', 'w');

disp('select edge of ball')
[xr, yr] = getpts(gca);

disp('select height of ball roi')
[xh,yh] = getpts(gca);

ballRadius = sqrt((xr-xc)^2+(yr-yc)^2);

bgFrame = zeros(sizeFrame);

plot([xc xr], [yc yr], 'Color', 'r', 'LineWidth', 3)
for yy = 1:sizeFrame(1)
    for xx = 1:sizeFrame(2)
    
        if (sqrt((xx-xc)^2+(yy-yc)^2)) < ballRadius && (yy < yh)

            bgFrame(yy,xx) = 1;
                    
        end
    
    end
end

diffInds = find(bgFrame==1);
numDiffInds = length(diffInds);

save('C:\thermal_data\diffInds', 'diffInds', 'numDiffInds')
disp('pixel indices acquired and saved')



