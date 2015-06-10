function krPlotEyePosition(handles)

ai = handles.ai;
dio = handles.dio;
warning('off')

whichScreen = 2;
res = Screen('Resolution',whichScreen);

% now open up a second matlab figure to be used to view eye position
axes(handles.EyePosition);cla;
axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
hold on
rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red');
axis off

% this is for the easy ending of programs
uic(1) = uicontrol('Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[400 350 60 20]);
drawnow

    function cb_EndTask(~,~)
        isRun = false;
    end

isRun = true;


while isRun
    
    [eyePosX eyePosY] = krPeekEyePos(ai);
    
    
    set(hEye, 'Position', [eyePosX eyePosY 25 25]);
    drawnow
    
    pause(0.00001)
end



% end task and clean out variables
stop(ai)
delete(uic);
axes(handles.EyePosition);cla;
axes(handles.TaskSpecificPlot);cla;


end % main