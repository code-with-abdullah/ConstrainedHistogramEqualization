function varargout = ConstrainedHistogramEqualization(varargin)
% CONSTRAINEDHISTOGRAMEQUALIZATION MATLAB code for ConstrainedHistogramEqualization.fig
%      CONSTRAINEDHISTOGRAMEQUALIZATION, by itself, creates a new CONSTRAINEDHISTOGRAMEQUALIZATION or raises the existing
%      singleton*.
%
%      H = CONSTRAINEDHISTOGRAMEQUALIZATION returns the handle to a new CONSTRAINEDHISTOGRAMEQUALIZATION or the handle to
%      the existing singleton*.
%
%      CONSTRAINEDHISTOGRAMEQUALIZATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONSTRAINEDHISTOGRAMEQUALIZATION.M with the given input arguments.
%
%      CONSTRAINEDHISTOGRAMEQUALIZATION('Property','Value',...) creates a new CONSTRAINEDHISTOGRAMEQUALIZATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ConstrainedHistogramEqualization_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ConstrainedHistogramEqualization_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ConstrainedHistogramEqualization

% Last Modified by GUIDE v2.5 28-May-2020 15:52:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ConstrainedHistogramEqualization_OpeningFcn, ...
                   'gui_OutputFcn',  @ConstrainedHistogramEqualization_OutputFcn, ...
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


% --- Executes just before ConstrainedHistogramEqualization is made visible.
function ConstrainedHistogramEqualization_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ConstrainedHistogramEqualization (see VARARGIN)

% Choose default command line output for ConstrainedHistogramEqualization
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ConstrainedHistogramEqualization wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ConstrainedHistogramEqualization_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LoadImageBTN.
function LoadImageBTN_Callback(hObject, eventdata, handles)
ImagesDirectory = '';
if strcmp(ImagesDirectory, '')
    ImagesDirectory = fullfile(matlabroot,'toolbox/images/imdata');
end
[selectedImage,cancelation] = imgetfile('InitialPath',ImagesDirectory);

% ----------------------------------------------------------------- %
% ------------------ Original Image Computations ------------------ %
% ----------------------------------------------------------------- %

OriginalImage = imread(selectedImage);

[m, n, channels] = size(OriginalImage);
if channels == 3
    OriginalImage = rgb2gray(OriginalImage);
end

% 1. Display the image that was read
imshow(OriginalImage,'Parent',handles.OriginalImageAxes);

% Display the entropy labels
set(handles.Entropy1LBL, 'Visible', 'on');
set(handles.Entropy2LBL, 'Visible', 'on');
set(handles.Entropy3LBL, 'Visible', 'on');
set(handles.Entropy4LBL, 'Visible', 'on');

set(handles.EntropyOriginal, 'Visible', 'on');
set(handles.EntropyHistEq, 'Visible', 'on');
set(handles.EntropyProposedHistEq, 'Visible', 'on');
set(handles.EntropyUnsharpMasking, 'Visible', 'on');

set(handles.ReApplyBTN, 'Enable', 'on');
set(handles.ReApplyProposedHeBTN, 'Enable', 'on');
set(handles.ReApplyProposedUmBTN, 'Enable', 'on');
set(handles.ResetBTN, 'Enable', 'on');

% 2. Not Display the histogram of original image

totalIntensities = 255;

% create new vectors for computation
probabilities = double(zeros(totalIntensities, 1));
commulativeProbabilities = double(zeros(totalIntensities, 1));

% range of 0 to 255 is theoretically converted to 1 to 256
for intensity = 1 : totalIntensities
    probabilities(intensity, 1) = length(OriginalImage(OriginalImage == intensity - 1));
end

% ---------------------------------------- %
% ----- 3. Entropy of Original Image ----- %
% ---------------------------------------- %
format short
EntropyOfOriginalImage = 0.00;
for intensity = 1 : totalIntensities
    if probabilities(intensity, 1) ~= 0
        EntropyOfOriginalImage = EntropyOfOriginalImage + (probabilities(intensity, 1) .* log2(probabilities(intensity, 1)));
    end
end

EntropyOfOriginalImage = -EntropyOfOriginalImage;
set(handles.EntropyOriginal, 'String', -EntropyOfOriginalImage);

% ----------------------------------------------------------------- %
% ----------- Basis Histogram Equalization Computations ----------- %
% ----------------------------------------------------------------- %

% 1. Display the basic HE image
histEqImage = histeq(OriginalImage);

imshow(histEqImage, 'Parent', handles.BasicHistEqAxes);

% 2. Display the histogram of basic HE image
axes(handles.HistogramForBasicHistEqAxes);
imhist(histEqImage);

set(handles.EntropyHistEq, 'String', entropy(histEqImage));


% ----------------------------------------------------------------- %
% ------------------- Proposed HE Computations -------------------- %
% ----------------------------------------------------------------- %


% divinding frequency of each intensity by total number of pixels to get
% probabilities
totalPixels = m .* n;
probabilities = probabilities ./ totalPixels;

commulativeProbabilities(1, 1) = probabilities(1, 1);
for intensity = 2 : totalIntensities
    commulativeProbabilities(intensity, 1) = probabilities(intensity, 1) + commulativeProbabilities(intensity - 1, 1);
end

% ---------------------------------------- %
% ------ weighing and thresholding ------- %
% ---------------------------------------- %

thresholdedProbabilities = double(zeros(totalIntensities, 1));
thresholdedCommulativeProbabilities = double(zeros(totalIntensities, 1));

v = str2double(char(get(handles.vValueTB,'String')));

if v > 1.0
    v = 1.0;
    set(handles.vValueTB, 'String', 1.0);
elseif v < 0.1
    v = 0.1;
    set(handles.vValueTB, 'String', 0.1);
end

r = str2double(char(get(handles.rValueTB,'String')));

if r > 1.0
    r = 1.0;
    set(handles.rValueTB, 'String', 1.0);
elseif r < 0.1
    r = 0.1;
    set(handles.rValueTB, 'String', 0.1);
end

pl = str2double(char(get(handles.plValueTB,'String')));

pu = double(v .* max(probabilities));

% Calculating weighed and thresholded probabilities
for k = 1 : totalIntensities
    if probabilities(k, 1) > pu
        thresholdedProbabilities(k, 1) = pu;
        
    elseif probabilities(k, 1) < pl
        thresholdedProbabilities(k, 1) = 0;
        
    else
        thresholdedProbabilities(k, 1) = (((probabilities(k, 1) - pl) ./ (pu - pl)) .^ r) .* pu;
        
    end
end

% Calculating weighed and thresholded commulative probabilities
thresholdedCommulativeProbabilities(1, 1) = thresholdedProbabilities(1, 1);

for intensity = 2 : totalIntensities
    thresholdedCommulativeProbabilities(intensity, 1) = thresholdedProbabilities(intensity, 1) + thresholdedCommulativeProbabilities(intensity - 1, 1);
end


% ---------------------------------------- %
% ------------ Equation no 05 ------------ %
% ---------------------------------------- %

X0 = min(OriginalImage(:));
XL_minusOne = max(OriginalImage(:));
XL_minusOneMinusX0 = double(XL_minusOne - X0);

NewImage = uint8(zeros(m, n));

NewImage(OriginalImage == 0) = XL_minusOneMinusX0 .* (0.5 .* thresholdedProbabilities(k, 1));

for k = 2 : totalIntensities
    NewImage(OriginalImage == k - 1) = XL_minusOneMinusX0 .* ((0.5 .* thresholdedProbabilities(k, 1)) + thresholdedCommulativeProbabilities(k - 1, 1));
end
NewImage = X0 + NewImage;

% 1. Display the proposed HE image
imshow(NewImage, 'Parent', handles.ProposedHistEqAxes);

% 2. Display the histogram of proposed HE image
axes(handles.HistogramForProposedHistEqAxes);
imhist(NewImage);

% ---------------------------------------- %
% ----- 3. Entropy of Proposed Image ----- %
% ---------------------------------------- %

probabilitiesOfNewImage = double(zeros(totalIntensities, 1));
for intensity = 1 : totalIntensities
    probabilitiesOfNewImage(intensity, 1) = length(NewImage(NewImage == intensity - 1));
end

probabilitiesOfNewImage = probabilitiesOfNewImage ./ totalPixels;

EntropyOfNewImage = 0.00;
for intensity = 1 : totalIntensities
    if probabilitiesOfNewImage(intensity, 1) ~= 0
        EntropyOfNewImage = EntropyOfNewImage + (probabilitiesOfNewImage(intensity, 1) .* log2(probabilitiesOfNewImage(intensity, 1)));
    end
end

EntropyOfNewImage = -EntropyOfNewImage;
set(handles.EntropyProposedHistEq, 'String', EntropyOfNewImage);

% ----------------------------------------------------------------- %
% ---------------- Unsharp Masking Computations ------------------- %
% ----------------------------------------------------------------- %

% ---------------------------------------- %
% ------------ Unsharp Masking ----------- %
% ---------------------------------------- %

selectedValueForWindowSize = get(handles.WindowSizeCB, 'Value');
if selectedValueForWindowSize == 1
    windowSize = 3;
elseif selectedValueForWindowSize == 2
    windowSize = 5;
elseif selectedValueForWindowSize == 3
    windowSize = 7;
elseif selectedValueForWindowSize == 4
    windowSize = 9;
elseif selectedValueForWindowSize == 5
    windowSize = 11;
elseif selectedValueForWindowSize == 6
    windowSize = 13;
elseif selectedValueForWindowSize == 7
    windowSize = 15;
elseif selectedValueForWindowSize == 2
    windowSize = 25;
else
    windowSize = 3;
end

isAverageSelected = get(handles.AverageRB, 'Value');

if isAverageSelected == 1
    filter = fspecial('average', windowSize);
else
    sigma = str2double(char(get(handles.SigmaTB, 'String')));
    filter = fspecial('gaussian', windowSize, sigma);
end

enhancedImage = imfilter(NewImage, filter);
k = str2double(char(get(handles.kValueTB,'String')));

if k > 1.0
    k = 1.0;
    set(handles.kValueTB, 'String', 1.0);
    
elseif k < 0.1
    k = 0.1;
    set(handles.kValueTB, 'String', 0.1);
end
subtractedImage = NewImage - (k .* enhancedImage);
unsharpMasked = NewImage + (k .* subtractedImage);

% 1. Display the unsharp masking image
imshow(unsharpMasked,'Parent',handles.ProposedHistEqAfterEnhancementAxes);

% 2. Display the histogram of unsharp masking image
axes(handles.HistogramForAfterEnhancementAxes);
imhist(unsharpMasked);

% ---------------------------------------- %
% -------- 3. Entropy of UM Image -------- %
% ---------------------------------------- %
set(handles.EntropyUnsharpMasking, 'String', entropy(unsharpMasked));


% hObject    handle to LoadImageBTN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function rValueTB_Callback(hObject, eventdata, handles)
% hObject    handle to rValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rValueTB as text
%        str2double(get(hObject,'String')) returns contents of rValueTB as a double


% --- Executes during object creation, after setting all properties.
function rValueTB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vValueTB_Callback(hObject, eventdata, handles)
% hObject    handle to vValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vValueTB as text
%        str2double(get(hObject,'String')) returns contents of vValueTB as a double


% --- Executes during object creation, after setting all properties.
function vValueTB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plValueTB_Callback(hObject, eventdata, handles)
% hObject    handle to plValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plValueTB as text
%        str2double(get(hObject,'String')) returns contents of plValueTB as a double


% --- Executes during object creation, after setting all properties.
function plValueTB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in WindowSizeCB.
function WindowSizeCB_Callback(hObject, eventdata, handles)
% hObject    handle to WindowSizeCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns WindowSizeCB contents as cell array
%        contents{get(hObject,'Value')} returns selected item from WindowSizeCB


% --- Executes during object creation, after setting all properties.
function WindowSizeCB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WindowSizeCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function SigmaTB_Callback(hObject, eventdata, handles)
% hObject    handle to SigmaTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SigmaTB as text
%        str2double(get(hObject,'String')) returns contents of SigmaTB as a double


% --- Executes during object creation, after setting all properties.
function SigmaTB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SigmaTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AverageRB.
function AverageRB_Callback(hObject, eventdata, handles)
set(handles.SigmaValueLBL, 'visible', 'off');
set(handles.SigmaTB, 'visible', 'off');
% hObject    handle to AverageRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AverageRB


% --- Executes on button press in GaussianRB.
function GaussianRB_Callback(hObject, eventdata, handles)
set(handles.SigmaValueLBL, 'visible', 'on');
set(handles.SigmaTB, 'visible', 'on');
% hObject    handle to GaussianRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of GaussianRB


% --- Executes on button press in ReApplyBTN.
function ReApplyBTN_Callback(hObject, eventdata, handles)
% hObject    handle to ReApplyBTN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)\

OriginalImage = getimage(handles.OriginalImageAxes);

[m, n, ~] = size(OriginalImage);

totalIntensities = 255;

% create new vectors for computation
probabilities = double(zeros(totalIntensities, 1));
commulativeProbabilities = double(zeros(totalIntensities, 1));

% range of 0 to 255 is theoretically converted to 1 to 256
for intensity = 1 : totalIntensities
    probabilities(intensity, 1) = length(OriginalImage(OriginalImage == intensity - 1));
end

% ----------------------------------------------------------------- %
% ------------------- Proposed HE Computations -------------------- %
% ----------------------------------------------------------------- %


% divinding frequency of each intensity by total number of pixels to get
% probabilities
totalPixels = m .* n;
probabilities = probabilities ./ totalPixels;

commulativeProbabilities(1, 1) = probabilities(1, 1);
for intensity = 2 : totalIntensities
    commulativeProbabilities(intensity, 1) = probabilities(intensity, 1) + commulativeProbabilities(intensity - 1, 1);
end

% ---------------------------------------- %
% ------ weighing and thresholding ------- %
% ---------------------------------------- %

thresholdedProbabilities = double(zeros(totalIntensities, 1));
thresholdedCommulativeProbabilities = double(zeros(totalIntensities, 1));

v = str2double(char(get(handles.vValueTB,'String')));

if v > 1.0
    v = 1.0;
    set(handles.vValueTB, 'String', 1.0);
elseif v < 0.1
    v = 0.1;
    set(handles.vValueTB, 'String', 0.1);
end

r = str2double(char(get(handles.rValueTB,'String')));

if r > 1.0
    r = 1.0;
    set(handles.rValueTB, 'String', 1.0);
elseif r < 0.1
    r = 0.1;
    set(handles.rValueTB, 'String', 0.1);
end
pl = str2double(char(get(handles.plValueTB,'String')));

pu = double(v .* max(probabilities));

% Calculating weighed and thresholded probabilities
for k = 1 : totalIntensities
    if probabilities(k, 1) > pu
        thresholdedProbabilities(k, 1) = pu;
        
    elseif probabilities(k, 1) < pl
        thresholdedProbabilities(k, 1) = 0;
        
    else
        thresholdedProbabilities(k, 1) = (((probabilities(k, 1) - pl) ./ (pu - pl)) .^ r) .* pu;
        
    end
end

% Calculating weighed and thresholded commulative probabilities
thresholdedCommulativeProbabilities(1, 1) = thresholdedProbabilities(1, 1);

for intensity = 2 : totalIntensities
    thresholdedCommulativeProbabilities(intensity, 1) = thresholdedProbabilities(intensity, 1) + thresholdedCommulativeProbabilities(intensity - 1, 1);
end


% ---------------------------------------- %
% ------------ Equation no 05 ------------ %
% ---------------------------------------- %

X0 = min(OriginalImage(:));
XL_minusOne = max(OriginalImage(:));
XL_minusOneMinusX0 = double(XL_minusOne - X0);

NewImage = uint8(zeros(m, n));

NewImage(OriginalImage == 0) = XL_minusOneMinusX0 .* (0.5 .* thresholdedProbabilities(k, 1));

for k = 2 : totalIntensities
    NewImage(OriginalImage == k - 1) = XL_minusOneMinusX0 .* ((0.5 .* thresholdedProbabilities(k, 1)) + thresholdedCommulativeProbabilities(k - 1, 1));
end
NewImage = X0 + NewImage;

% 1. Display the proposed HE image
imshow(NewImage, 'Parent', handles.ProposedHistEqAxes);

% 2. Display the histogram of proposed HE image
axes(handles.HistogramForProposedHistEqAxes);
imhist(NewImage);

% ---------------------------------------- %
% ----- 3. Entropy of Proposed Image ----- %
% ---------------------------------------- %

probabilitiesOfNewImage = double(zeros(totalIntensities, 1));
for intensity = 1 : totalIntensities
    probabilitiesOfNewImage(intensity, 1) = length(NewImage(NewImage == intensity - 1));
end

probabilitiesOfNewImage = probabilitiesOfNewImage ./ totalPixels;

EntropyOfNewImage = 0.00;
for intensity = 1 : totalIntensities
    if probabilitiesOfNewImage(intensity, 1) ~= 0
        EntropyOfNewImage = EntropyOfNewImage + (probabilitiesOfNewImage(intensity, 1) .* log2(probabilitiesOfNewImage(intensity, 1)));
    end
end

EntropyOfNewImage = -EntropyOfNewImage;
set(handles.EntropyProposedHistEq, 'String', EntropyOfNewImage);

% ----------------------------------------------------------------- %
% ---------------- Unsharp Masking Computations ------------------- %
% ----------------------------------------------------------------- %

% ---------------------------------------- %
% ------------ Unsharp Masking ----------- %
% ---------------------------------------- %

selectedValueForWindowSize = get(handles.WindowSizeCB, 'Value');
if selectedValueForWindowSize == 1
    windowSize = 3;
elseif selectedValueForWindowSize == 2
    windowSize = 5;
elseif selectedValueForWindowSize == 3
    windowSize = 7;
elseif selectedValueForWindowSize == 4
    windowSize = 9;
elseif selectedValueForWindowSize == 5
    windowSize = 11;
elseif selectedValueForWindowSize == 6
    windowSize = 13;
elseif selectedValueForWindowSize == 7
    windowSize = 15;
elseif selectedValueForWindowSize == 2
    windowSize = 25;
else
    windowSize = 3;
end

isAverageSelected = get(handles.AverageRB, 'Value');

if isAverageSelected == 1
    filter = fspecial('average', windowSize);
else
    sigma = str2double(char(get(handles.SigmaTB, 'String')));
    filter = fspecial('gaussian', windowSize, sigma);
end

enhancedImage = imfilter(NewImage, filter);
k = str2double(char(get(handles.kValueTB,'String')));

if k > 1.0
    k = 1.0;
    set(handles.kValueTB, 'String', 1.0);
    
elseif k < 0.1
    k = 0.1;
    set(handles.kValueTB, 'String', 0.1);
end

subtractedImage = NewImage - (k .* enhancedImage);

unsharpMasked = NewImage + (k .* subtractedImage);

% 1. Display the unsharp masking image
imshow(unsharpMasked,'Parent',handles.ProposedHistEqAfterEnhancementAxes);

% 2. Display the histogram of unsharp masking image
axes(handles.HistogramForAfterEnhancementAxes);
imhist(unsharpMasked);

% ---------------------------------------- %
% -------- 3. Entropy of UM Image -------- %
% ---------------------------------------- %
set(handles.EntropyUnsharpMasking, 'String', entropy(unsharpMasked));



function kValueTB_Callback(hObject, eventdata, handles)
% hObject    handle to kValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of kValueTB as text
%        str2double(get(hObject,'String')) returns contents of kValueTB as a double


% --- Executes during object creation, after setting all properties.
function kValueTB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to kValueTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ReApplyProposedHeBTN.
function ReApplyProposedHeBTN_Callback(hObject, eventdata, handles)
OriginalImage = getimage(handles.OriginalImageAxes);

[m, n, ~] = size(OriginalImage);

totalIntensities = 255;

% create new vectors for computation
probabilities = double(zeros(totalIntensities, 1));
commulativeProbabilities = double(zeros(totalIntensities, 1));

% range of 0 to 255 is theoretically converted to 1 to 256
for intensity = 1 : totalIntensities
    probabilities(intensity, 1) = length(OriginalImage(OriginalImage == intensity - 1));
end

% ----------------------------------------------------------------- %
% ------------------- Proposed HE Computations -------------------- %
% ----------------------------------------------------------------- %


% divinding frequency of each intensity by total number of pixels to get
% probabilities
totalPixels = m .* n;
probabilities = probabilities ./ totalPixels;

commulativeProbabilities(1, 1) = probabilities(1, 1);
for intensity = 2 : totalIntensities
    commulativeProbabilities(intensity, 1) = probabilities(intensity, 1) + commulativeProbabilities(intensity - 1, 1);
end

% ---------------------------------------- %
% ------ weighing and thresholding ------- %
% ---------------------------------------- %

thresholdedProbabilities = double(zeros(totalIntensities, 1));
thresholdedCommulativeProbabilities = double(zeros(totalIntensities, 1));

v = str2double(char(get(handles.vValueTB,'String')));

if v > 1.0
    v = 1.0;
    set(handles.vValueTB, 'String', 1.0);
elseif v < 0.1
    v = 0.1;
    set(handles.vValueTB, 'String', 0.1);
end

r = str2double(char(get(handles.rValueTB,'String')));

if r > 1.0
    r = 1.0;
    set(handles.rValueTB, 'String', 1.0);
elseif r < 0.1
    r = 0.1;
    set(handles.rValueTB, 'String', 0.1);
end

pl = str2double(char(get(handles.plValueTB,'String')));

pu = double(v .* max(probabilities));

% Calculating weighed and thresholded probabilities
for k = 1 : totalIntensities
    if probabilities(k, 1) > pu
        thresholdedProbabilities(k, 1) = pu;
        
    elseif probabilities(k, 1) < pl
        thresholdedProbabilities(k, 1) = 0;
        
    else
        thresholdedProbabilities(k, 1) = (((probabilities(k, 1) - pl) ./ (pu - pl)) .^ r) .* pu;
        
    end
end

% Calculating weighed and thresholded commulative probabilities
thresholdedCommulativeProbabilities(1, 1) = thresholdedProbabilities(1, 1);

for intensity = 2 : totalIntensities
    thresholdedCommulativeProbabilities(intensity, 1) = thresholdedProbabilities(intensity, 1) + thresholdedCommulativeProbabilities(intensity - 1, 1);
end


% ---------------------------------------- %
% ------------ Equation no 05 ------------ %
% ---------------------------------------- %

X0 = min(OriginalImage(:));
XL_minusOne = max(OriginalImage(:));
XL_minusOneMinusX0 = double(XL_minusOne - X0);

NewImage = uint8(zeros(m, n));

NewImage(OriginalImage == 0) = XL_minusOneMinusX0 .* (0.5 .* thresholdedProbabilities(k, 1));

for k = 2 : totalIntensities
    NewImage(OriginalImage == k - 1) = XL_minusOneMinusX0 .* ((0.5 .* thresholdedProbabilities(k, 1)) + thresholdedCommulativeProbabilities(k - 1, 1));
end
NewImage = X0 + NewImage;

% 1. Display the proposed HE image
imshow(NewImage, 'Parent', handles.ProposedHistEqAxes);

% 2. Display the histogram of proposed HE image
axes(handles.HistogramForProposedHistEqAxes);
imhist(NewImage);

% ---------------------------------------- %
% ----- 3. Entropy of Proposed Image ----- %
% ---------------------------------------- %

probabilitiesOfNewImage = double(zeros(totalIntensities, 1));
for intensity = 1 : totalIntensities
    probabilitiesOfNewImage(intensity, 1) = length(NewImage(NewImage == intensity - 1));
end

probabilitiesOfNewImage = probabilitiesOfNewImage ./ totalPixels;

EntropyOfNewImage = 0.00;
for intensity = 1 : totalIntensities
    if probabilitiesOfNewImage(intensity, 1) ~= 0
        EntropyOfNewImage = EntropyOfNewImage + (probabilitiesOfNewImage(intensity, 1) .* log2(probabilitiesOfNewImage(intensity, 1)));
    end
end

EntropyOfNewImage = -EntropyOfNewImage;
set(handles.EntropyProposedHistEq, 'String', EntropyOfNewImage);
% hObject    handle to ReApplyProposedHeBTN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in ReApplyProposedUmBTN.
function ReApplyProposedUmBTN_Callback(hObject, eventdata, handles)
NewImage = getimage(handles.ProposedHistEqAxes);

% hObject    handle to ReApplyProposedUmBTN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% ----------------------------------------------------------------- %
% ---------------- Unsharp Masking Computations ------------------- %
% ----------------------------------------------------------------- %

% ---------------------------------------- %
% ------------ Unsharp Masking ----------- %
% ---------------------------------------- %

selectedValueForWindowSize = get(handles.WindowSizeCB, 'Value');
if selectedValueForWindowSize == 1
    windowSize = 3;
elseif selectedValueForWindowSize == 2
    windowSize = 5;
elseif selectedValueForWindowSize == 3
    windowSize = 7;
elseif selectedValueForWindowSize == 4
    windowSize = 9;
elseif selectedValueForWindowSize == 5
    windowSize = 11;
elseif selectedValueForWindowSize == 6
    windowSize = 13;
elseif selectedValueForWindowSize == 7
    windowSize = 15;
elseif selectedValueForWindowSize == 2
    windowSize = 25;
else
    windowSize = 3;
end

isAverageSelected = get(handles.AverageRB, 'Value');

if isAverageSelected == 1
    filter = fspecial('average', windowSize);
else
    sigma = str2double(char(get(handles.SigmaTB, 'String')));
    filter = fspecial('gaussian', windowSize, sigma);
end

enhancedImage = imfilter(NewImage, filter);
k = str2double(char(get(handles.kValueTB,'String')));

if k > 1.0
    k = 1.0;
    set(handles.kValueTB, 'String', 1.0);
    
elseif k < 0.1
    k = 0.1;
    set(handles.kValueTB, 'String', 0.1);
end

subtractedImage = NewImage - (k .* enhancedImage);

unsharpMasked = NewImage + (k .* subtractedImage);

% 1. Display the unsharp masking image
imshow(unsharpMasked,'Parent',handles.ProposedHistEqAfterEnhancementAxes);

% 2. Display the histogram of unsharp masking image
axes(handles.HistogramForAfterEnhancementAxes);
imhist(unsharpMasked);

% ---------------------------------------- %
% -------- 3. Entropy of UM Image -------- %
% ---------------------------------------- %
set(handles.EntropyUnsharpMasking, 'String', entropy(unsharpMasked));


% --- Executes on button press in ResetBTN.
function ResetBTN_Callback(hObject, eventdata, handles)
% hObject    handle to ResetBTN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cla(handles.OriginalImageAxes,'reset');

cla(handles.BasicHistEqAxes,'reset');
cla(handles.HistogramForBasicHistEqAxes,'reset');

cla(handles.ProposedHistEqAxes,'reset');
cla(handles.HistogramForProposedHistEqAxes,'reset');


cla(handles.ProposedHistEqAfterEnhancementAxes,'reset');
cla(handles.HistogramForAfterEnhancementAxes,'reset');

set(handles.rValueTB, 'String', 1.0);
set(handles.vValueTB, 'String', 1.0);
set(handles.plValueTB, 'String', 0.0001);
set(handles.kValueTB, 'String', 1.0);
set(handles.AverageRB, 'Value', 1.0);
set(handles.SigmaValueLBL, 'Visible', 'off');
set(handles.SigmaTB, 'Visible', 'off');
set(handles.SigmaTB, 'String', 1.5);

set(handles.Entropy1LBL, 'Visible', 'off');
set(handles.Entropy2LBL, 'Visible', 'off');
set(handles.Entropy3LBL, 'Visible', 'off');
set(handles.Entropy4LBL, 'Visible', 'off');

set(handles.EntropyOriginal, 'Visible', 'off');
set(handles.EntropyOriginal, 'String', '');

set(handles.EntropyHistEq, 'Visible', 'off');
set(handles.EntropyHistEq, 'String', '');

set(handles.EntropyProposedHistEq, 'Visible', 'off');
set(handles.EntropyProposedHistEq, 'String', '');

set(handles.EntropyUnsharpMasking, 'Visible', 'off');
set(handles.EntropyUnsharpMasking, 'String', '');

set(handles.WindowSizeCB, 'Value', 1.0);

set(handles.ReApplyBTN, 'Enable', 'off');
set(handles.ReApplyProposedHeBTN, 'Enable', 'off');
set(handles.ReApplyProposedUmBTN, 'Enable', 'off');
set(handles.ResetBTN, 'Enable', 'off');
