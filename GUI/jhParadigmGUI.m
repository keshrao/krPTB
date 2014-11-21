function varargout = jhParadigmGUI(varargin)
% JHPARADIGMGUI MATLAB code for jhParadigmGUI.fig
%      JHPARADIGMGUI, by itself, creates a new JHPARADIGMGUI or raises the existing
%      singleton*.
%
%      H = JHPARADIGMGUI returns the handle to a new JHPARADIGMGUI or the handle to
%      the existing singleton*.
%
%      JHPARADIGMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in JHPARADIGMGUI.M with the given input arguments.
%
%      JHPARADIGMGUI('Property','Value',...) creates a new JHPARADIGMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before jhParadigmGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to jhParadigmGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help jhParadigmGUI

% Last Modified by GUIDE v2.5 14-Oct-2014 15:32:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @jhParadigmGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @jhParadigmGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before jhParadigmGUI is made visible.
function jhParadigmGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to jhParadigmGUI (see VARARGIN)
clc

% Choose default command line output for jhParadigmGUI
handles.output = hObject;


% Connect the daq card
[ai, dio] = krConnectDAQInf();
handles.ai = ai;
handles.dio = dio;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using jhParadigmGUI.
if strcmp(get(hObject,'Visible'),'off')

    
end
% UIWAIT makes jhParadigmGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = jhParadigmGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(get(handles.SetTrialNumber,'Value') == 0)
    set(handles.SetTrialNumber,'Value',100);
end

% Update handles structure
guidata(hObject, handles);

popup_sel_index = get(handles.ChooseParadigm, 'Value');
switch popup_sel_index
    case 1
        krDirReqSingleSac(get(handles.SetTrialNumber,'Value'),handles);
    case 2
        krFwdCorr_OnlinePlot(get(handles.SetTrialNumber,'Value'),handles);
    case 3
        krFwdCorr_MScale(get(handles.SetTrialNumber,'Value'),handles);
    case 4
        krFwdCorr_SingleSaccade(get(handles.SetTrialNumber,'Value'),handles);
    case 5
        krFwdCorr_SingleSaccade_MScaling(get(handles.SetTrialNumber,'Value'),handles);
    case 6
        krCal(get(handles.SetTrialNumber,'Value'),handles);
    case 7 
        krFwdCorr_FreeMap(get(handles.SetTrialNumber,'Value'),handles);
    case 8
        krFwdCorr_FreeMap_photoupdate(get(handles.SetTrialNumber,'Value'),handles);
    case 9
        krFwdCorr_OnlinePlot_photoUpdate(get(handles.SetTrialNumber,'Value'),handles);
end


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% ----6----------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in ChooseParadigm.
function ChooseParadigm_Callback(hObject, eventdata, handles)
% hObject    handle to ChooseParadigm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ChooseParadigm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ChooseParadigm
%choice = get(hObject,'String');
set(handles.ChooseParadigm, 'Value', get(hObject,'Value'));
 



% --- Executes during object creation, after setting all properties.
function ChooseParadigm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChooseParadigm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'krDirReqSingleSac','krFwdCorr_OnlinePlot','krFwdCorr_MScale', ... 
                    'krFwdCorr_SingleSaccade','krFwdCorr_SingleSaccade_MScaling','krCal','FreeMap',...
                     'krFwdCorr_FreeMap_photoupdate','krFwdCorr_OnlinePlot_photoUpdate'});


% --- Executes on button press in krCalibrateEyePos.
function krCalibrateEyePos_Callback(hObject, eventdata, handles)
% hObject    handle to krCalibrateEyePos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    krCalibrateEyeCoil(handles);
catch
end


% --- Executes on button press in Reward.
function Reward_Callback(hObject, eventdata, handles)
% hObject    handle to Reward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
krDeliverReward(handles.dio,1);



function SetTrialNumber_Callback(hObject, eventdata, handles)
% hObject    handle to SetTrialNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SetTrialNumber as text
%        str2double(get(hObject,'String')) returns contents of SetTrialNumber as a double
ntrls = str2num(get(hObject,'String'));
set(handles.SetTrialNumber,'Value', ntrls);


% --- Executes during object creation, after setting all properties.
function SetTrialNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SetTrialNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function TrialNumber_Callback(hObject, eventdata, handles)
% hObject    handle to TrialNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TrialNumber as text
%        str2double(get(hObject,'String')) returns contents of TrialNumber as a double


% --- Executes during object creation, after setting all properties.
function TrialNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrialNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SuccessCount_Callback(hObject, eventdata, handles)
% hObject    handle to SuccessCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SuccessCount as text
%        str2double(get(hObject,'String')) returns contents of SuccessCount as a double


% --- Executes during object creation, after setting all properties.
function SuccessCount_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SuccessCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function EyePosition_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EyePosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate EyePosition


% --- Executes on button press in ResetEyePlot.
function ResetEyePlot_Callback(hObject, eventdata, handles)
% hObject    handle to ResetEyePlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse press over axes background.
function EyePosition_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EyePosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in MonitorSaccades_PB.
function MonitorSaccades_PB_Callback(hObject, eventdata, handles)
% hObject    handle to MonitorSaccades_PB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
krMonitorSaccades(handles)

