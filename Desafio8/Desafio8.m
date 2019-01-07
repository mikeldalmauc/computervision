imagen_validacion = imread('validacion.gif');
numRows = 1200;
numCols = 1200;

% longitudes de onda
wavelengthMin = 4/sqrt(2);
wavelengthMax = hypot(numRows,numCols);
n = floor(log2(wavelengthMax/wavelengthMin));
wavelength = 2.^(0:(n-2)) * wavelengthMin;

% Orientaciones
deltaTheta = 45;
orientation = 0:deltaTheta:(180-deltaTheta);

% Banco de filtros de Gabor
g = gabor(wavelength, orientation);

% Extraer las magnitudes de gabor,
% Cada magnitud MxN de la imagen resultante de gabormag(:,:,ind) 
% es el resultado del correspondiente filtro de gabor g(ind).
gabormag = imgaborfilt(imagen_validacion,g);

% Aplicación de un filtro gaussiano para eliminar las variaciones locales
% en la magnitud del filtro de gabor.
for i = 1:length(g)
    %Calculo del paso del filtro gausiano en función de cada longitud de
    %onda y suavizado por K
    sigma = 0.5*g(i).Wavelength; 
    K = 3;
    gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),K*sigma); 
end

%  Agregar un mapa de información de ubicación espacial tanto en X como en Y.
X = 1:numCols;
Y = 1:numRows;
%   [X,Y] = MESHGRID(xgv,ygv) replicates the grid vectors xgv and ygv to 
%   produce the coordinates of a rectangular grid (X, Y). The grid vector
%   xgv is replicated numel(ygv) times to form the columns of X. The grid 
%   vector ygv is replicated numel(xgv) times to form the rows of Y.
[X,Y] = meshgrid(X,Y);
%   CAT(DIM,A,B) concatenates the arrays A and B along
%   the dimension DIM.  
featureSet = cat(3,gabormag,X);
featureSet = cat(3,featureSet,Y);
%  1200x1200x32 ->  1200x1200x34

numPoints = numRows*numCols;
%   RESHAPE(X,M,N) or RESHAPE(X,[M,N]) returns the M-by-N matrix 
%   whose elements are taken columnwise from X. An error results 
%   if X does not have M*N elements.
X = reshape(featureSet,numPoints,[]);
% Matriz de caraterísticas -> vector de características
% 1200x1200x34 -> 1440000x34

%   C = BSXFUN(FUNC,A,B) applies the element-by-element binary operation
%   specified by the function handle FUNC to arrays A and B, with implicit
%   expansion enabled.
% Normalizar las características para que tengan media zero y varianza
% unitaria
X = bsxfun(@minus, X, mean(X));
X = bsxfun(@rdivide,X,std(X));

% Aplicar clustering k means
% iterations = 5;
% s = (numRows/4);% 300 px
% centroids = zeros(16,34);
% k = 1;
% for i = 0:3
%     for j = 0:3
%         centroids(k,:) = X(i*s+(s/2) + j*s+(s/2),:);
%         k = k +1 ;
%     end
% end

% centroids = repmat(centroids, [ 1 1 iterations]);
L = kmeans(X,16,'Replicates',5);
 
%% MOstrar resultado
L = reshape(L,[numRows numCols]);
figure
imshow(label2rgb(L))
