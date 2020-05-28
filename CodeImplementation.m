ImagePath = '';

tic

OriginalImage = imread(ImagePath); 
[m, n, channels] = size(OriginalImage);
if channels == 3
    OriginalImage = rgb2gray(OriginalImage);
end


powerOfMaximumIntersity = 8;
totalIntensities = 2^powerOfMaximumIntersity;

% vectors for computations
probabilities = double(zeros(totalIntensities, 1));
commulativeProbabilities = double(zeros(totalIntensities, 1));

% range of 0 to 255 is theoretically converted to 1 to 256
for intensity = 1 : totalIntensities
    probabilities(intensity, 1) = length(OriginalImage(OriginalImage == intensity - 1));
end

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

v = 1.0;
r = 1.0;
pl = 0.0001;

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

% ---------------------------------------- %
% ------------ Unsharp Masking ----------- %
% ---------------------------------------- %

AverageFilter = fspecial('average', 9);
AverageImage = imfilter(NewImage, AverageFilter);

GaussianFilter = fspecial('gaussian', 13, 2);
GaussianImage = imfilter(NewImage, GaussianFilter);



k = 0.9;

UnsharpMaskAverageFilter = NewImage + (k .* (NewImage - AverageImage));
UnsharpMaskGaussianFilter = NewImage + (k .* (NewImage - GaussianImage));

% ---------------------------------------- %
% ---------------- Entropy --------------- %
% ---------------------------------------- %

probabilitiesOfNewImage = double(zeros(totalIntensities, 1));
for intensity = 1 : totalIntensities
    probabilitiesOfNewImage(intensity, 1) = length(UnsharpMaskGaussianFilter(UnsharpMaskGaussianFilter == intensity - 1));
end
probabilitiesOfNewImage = probabilitiesOfNewImage ./ totalPixels;


EntropyOfOriginalImage = 0.00;
EntropyOfNewImage = 0.00;

for intensity = 1 : totalIntensities
    if probabilities(intensity, 1) ~= 0
        EntropyOfOriginalImage = EntropyOfOriginalImage + (probabilities(intensity, 1) .* log2(probabilities(intensity, 1)));
    end
    if probabilitiesOfNewImage(intensity, 1) ~= 0
        EntropyOfNewImage = EntropyOfNewImage + (probabilitiesOfNewImage(intensity, 1) .* log2(probabilitiesOfNewImage(intensity, 1)));
    end
end

EntropyOfOriginalImage = -EntropyOfOriginalImage
EntropyOfNewImage = -EntropyOfNewImage

% ---------------------------------------- %
% ------------ Display results ----------- %
% ---------------------------------------- %


subplot(5, 2, 1), imshow(OriginalImage, []), title('Original Image');

subplot(5, 2, 2);
histogram(OriginalImage);

subplot(5, 2, 3), imshow(histeq(OriginalImage), []), title('Basic Histogram Equalization');

subplot(5, 2, 4);
histogram(histeq(OriginalImage));


subplot(5, 2, 5), imshow(NewImage, []), title('Proposed Histogram Equalization');

subplot(5, 2, 6);
histogram(NewImage);

subplot(5, 2, 7), imshow(UnsharpMaskAverageFilter, []), title('Unsharp masking with average filter');
subplot(5, 2, 8);
histogram(UnsharpMaskAverageFilter);

subplot(5, 2, 9), imshow(UnsharpMaskGaussianFilter, []), title('Unsharp masking with gaussian filter');
subplot(5, 2, 10);
histogram(UnsharpMaskGaussianFilter);

toc