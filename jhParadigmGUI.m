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

% Last Modified by GUIDE v2.5 15-Sep-2014 17:23:35

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

% Choose default command line output for jhParadigmGUI
handles.output = hObject;

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

popup_sel_index = get(handles.ChooseParadigm, 'String');
switch popup_sel_index
    case 'krCal'
        krCal();
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

% --------------------------------------------------------------------
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
set(hObject, 'String', 'krCal')



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

set(hObject, 'String', {'krCal'});


% --- Executes on button press in krCalibrateEyePos.
function krCalibrateEyePos_Callback(hObject, eventdata, handles)
% hObject    handle to krCalibrateEyePos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    krCalibrateEyeCoil();
catch
end


% --- Executes on button press in Reward.
function Reward_Callback(hObject, eventdata, handles)
% hObject    handle to Reward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
krDeliverReward();

