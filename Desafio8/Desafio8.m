imagen_validacion = imread('validacion.gif');
numRows = 1200;
numCols = 1200;

wavelengthMin = 4/sqrt(2);
wavelengthMax = hypot(numRows,numCols);
n = floor(log2(wavelengthMax/wavelengthMin));
wavelength = 2.^(0:(n-2)) * wavelengthMin;

deltaTheta = 45;
orientation = 0:deltaTheta:(180-deltaTheta);
g = gabor(wavelength, orientacion);
gabormag = imgaborfilt(imagen_validacion,g);

for i = 1:length(g)
    sigma = 0.5*g(i).Wavelength;
    K = 3;
    gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),K*sigma); 
end

% When constructing Gabor feature sets for classification, it is useful to add a map of spatial location information in both X and Y. This additional information allows the classifier to prefer groupings which are close together spatially.
X = 1:numCols;
Y = 1:numRows;
[X,Y] = meshgrid(X,Y);
featureSet = cat(3,gabormag,X);
featureSet = cat(3,featureSet,Y);

%Normalize the features to be zero mean, unit variance.
numPoints = numRows*numCols;
X = reshape(featureSet,numRows*numCols,[]);

%indices = kmeans(muestra,16);
X = bsxfun(@minus, X, mean(X));
X = bsxfun(@rdivide,X,std(X));


L = kmeans(X,16,'Replicates',5);

%% MOstrar resultado
L = reshape(L,[numRows numCols]);
figure
imshow(label2rgb(L))
