  %% Configuration Parameters

% Folder containing the images
folder = "C:\Users\Mikel\Dropbox\docencia vision 2018\alumnos\DALMAU CHERINO MIKEL\Desafio2\martillos";

% Value for Gaussian filtering, negative to skip step
sigma = -2; 

% Binarization threshold, Otsus threshold used if less than 0
threshold = 0.95;

% Min pixels not to delete unconnected component, negative to skip step
connectedComponentMinPixels = 6500; 

% Wether to rotate images or not
rotate = true;


%% MAIN LOOP 
%
%  reading of images in batch and calculation of properties
%
%
dirlist = dir(folder+'\martillo*');
hammers = length(dirlist);
for i = 1:hammers
    [propertiesR, step] = properties(dirlist(i).name, sigma, threshold, connectedComponentMinPixels, rotate);
    cells(i,1:4) = {dirlist(i).name,propertiesR, step, true};
end

dirlist = cat(1,dir(folder+'\gato*'),dir(folder+'\taladro*'),dir(folder+'\llave*'),dir(folder+'\hacha*'),dir(folder+'\destorni*'));
for i = 1:length(dirlist)
    [propertiesR, step] = properties(dirlist(i).name, sigma, threshold, connectedComponentMinPixels, rotate);
    cells(i+hammers,1:4) = {dirlist(i).name,propertiesR, step, false};
end

m = propertyExtractor(cells);

% 1 - Originals
% 2 - Greyscale
% 3 - Pre Binarization Greyscale
% 4 - Binarized
% 5 - After Binarization Processed
% 6 - Complement image
% 7 - After Complement image
% 8 - Rotated imaged
%plotResults(cells,8);

% Con Otsus y desenfoque a 4 desaparece la raya del martillo
%plotProcess(cells,17);

%% Image Processing PIPE-LINE
%
%
%
function [propertiesR, step] = properties(image, sigma, threshold, connectedComponentMinPixels, rotate)

    % Read image
    original = imread(image);
    step(1)= {original};
    
    % Transform to greyscale
    greyScale = rgb2gray(original);
    step(2)= {greyScale};

    % Apply before binarization operations
    toBinarize = onBeforeBinarization(greyScale, sigma);
    step(3)= {toBinarize};
    
    % binarize image
    binary = binarize(toBinarize,threshold);
    step(4)= {binary};
    
    % Apply after binarization operations
    toComplement = onAfterBinarization(binary,connectedComponentMinPixels);
    step(5)= {toComplement};
    
    % Get the complement of the binary image to use in regionprops
    complement = imcomplement(toComplement);
    step(6)= {complement};
    
    % Apply functions to complement image
    afterComplement = onAfterComplement(complement);
    step(7) = {afterComplement};
   
    % RETO 3 Rotate images
    rotated = VRotate(afterComplement, rotate);
    step(8)= {rotated};
    
    % Calculate properties from the rotated image
    propertiesR = pickGreatestCC(regionprops(rotated,'centroid','BoundingBox','Area', 'Orientation','Perimeter','Extrema','ConvexHull','Eccentricity','MajorAxisLength','MinorAxisLength','Solidity'));
    
end

% Functions applied before the binarization step, on greyscale image
%  
%  GSI - Grey Scale Image
%  sigma - Factor for gaussian filtering 2, 4, 8
%
function toBinarize = onBeforeBinarization(GSI, sigma)
    toBinarize = GSI;
    
    if sigma > 0
        toBinarize = imgaussfilt(toBinarize, sigma);
    end
end

%  I - GreyScale image to binarize
%  T -Threshold or negative for Otsus
function binary = binarize(I,T)

    if T >= 0
        binary = im2bw(I,T);
    else
        binary = imbinarize(I);
    end
end

% Functions applied after the binarization step
%
function toComplement = onAfterBinarization(BW,connectedComponentMinPixels)

    toComplement = BW;
    
    % Erode image to make black area greater, thus, filling the white holes
    % in the hammers
    SE = strel('diamond',1);
    toComplement = imerode(toComplement,SE);

    % Remove small pixels areas leaving 1 connected component if possible
    toComplement = bwareaopen(toComplement,connectedComponentMinPixels);
    
end

% Function to remove small white pixel areas lost around
%
function complement = onAfterComplement(complement)
    % Supression of small white pixels creted by erosion before complement
    complement = bwareaopen(complement,1000);
end

% Given a RegionProps struct list, picks the greatest connected componenet
% properties struct based on the Area size.
%
function p = pickGreatestCC(props)
    area = [props.Area].';
    [~,ind] = max(area);
    p = props(ind);
end

% Computes the rotation of images with the following parameters:
%
% Depending on the position of the extrema points and the centroid, the 
%       rotation might vary.
% 
% angle - The angle seeked is -90 degrees
%
% bilinear - Bilinear interpolation; the output pixel value is a weighted 
%               average of pixels in the nearest 2-by-2 neighborhood
%
function rotated = VRotate(I, rotate)

    if rotate == false 
        rotated = I;
        return;
    end
    
    % Extracting the properties and take those of the conected component
    % with greatest area
    props = pickGreatestCC(regionprops(I,'Area','Orientation'));

    % We want theta + orientation to be equal to -90
    theta = -90 - props.Orientation;
    
    rotated = imrotate(I,theta,'bilinear','loose');
    
    % Compute regionprops again to get the actual centroid and bounding box, 
    propertiesR = pickGreatestCC(regionprops(rotated,'centroid','BoundingBox','Area','Extrema'));
        
    if centroidInLowerHalf(propertiesR) || hammerHeadPosition(propertiesR,true,2)
         theta = theta + 180;
         rotated = imrotate(I,theta,'bilinear','loose');
    end
    
    
end

% Condition 1, centroid in the lower half.
% if the centroid is in the lower half of the BB, then probably the
% hammer is upside down and should be rotated again a 180 degrees.
%
function cond1 = centroidInLowerHalf(propertiesR)

    y = propertiesR.BoundingBox(2);
    yw = propertiesR.BoundingBox(4);
    yc =  propertiesR.Centroid(2);
    
    cond1 = yc > (y+(yw/2));
end

% Condition 2,
% We want extrema points top-right top-left to be in the upper
% half and the rest of points in the bottom half, meaning the head of
% the hammer is upside down.
%
% [top-left top-right right-top right-bottom bottom-right bottom-left left-bottom left-top]
% 
% propertiesR - Regionprops struct
% slices - Numer of pieces to divide area into
% 
function cond2 = hammerHeadPosition(propertiesR,upsideDown,slices)
    
    y = propertiesR.BoundingBox(2);
    yw = propertiesR.BoundingBox(4);
    thresholdY = y+(yw/slices);
    
    e = propertiesR.Extrema;
    topLeftY = e(1,2);     topRightY = e(2,2);
    righTopY = e(3,2);      rightBottomY = e(4,2);
    bottomRightY = e(5,2);  bottomLeftY = e(6,2);
    leftBottomY = e(7,2);   leftTopY = e(8,2);
    
    if upsideDown
        % Only this 2 points are in the upper section
        cond21 = topLeftY < thresholdY ;
        cond22 = topRightY < thresholdY;

        % Majority of points are in the lower section
        cond23 = righTopY > thresholdY;
        cond24 = rightBottomY > thresholdY;
        cond25 = leftBottomY > thresholdY;
        cond26 = leftTopY > thresholdY;
        cond27 = bottomRightY > thresholdY;
        cond28 = bottomLeftY > thresholdY;
    
    else
         % Majority of points are in the lower section
        cond21 = topLeftY < thresholdY ;
        cond22 = topRightY < thresholdY;
        cond23 = righTopY < thresholdY;
        cond24 = rightBottomY < thresholdY;
        cond25 = leftBottomY < thresholdY;
        cond26 = leftTopY < thresholdY;
        
        % Only this 2 points are in the bottom section
        cond27 = bottomRightY > thresholdY;
        cond28 = bottomLeftY > thresholdY;
    end
    
    cond2 = cond21 && cond22 && cond23 && cond24 && cond25 && cond26 && cond27 && cond28;
end

%% Classification Variables
%
%  
%
%
function m=propertyExtractor(cells)
    
    for i=1:length(cells(:,1))
        
        isHammer = cells{i,4};
        
        props = cells{i,2};

        % Bounding Box Height Width Rate
        bb = props.BoundingBox;
        bbHeightWidthRate = bb(4)/bb(3);

        % Rate Between BB perimeter and real perimeter
        bbPerimeter = 2*(bb(4) + bb(3));
        perimetersRate = bbPerimeter/props.Perimeter;

        % Extrema points area
        headInUpperThird = hammerHeadPosition(props, false,3);

        headInUpperFourth = hammerHeadPosition(props, false,4);

        headInUpperFifth = hammerHeadPosition(props, false,5);

        % Relation Between BB Area and real Area
        areasRate = bb(4)*bb(3)/props.Area;

        % Eccentricity
        eccentricity = props.Eccentricity;
        
        % Solidity
        solidity = props.Solidity;
        
        m(i,:)= [bbHeightWidthRate,perimetersRate,headInUpperThird,headInUpperFourth,headInUpperFifth,areasRate,eccentricity,solidity,isHammer];
    end
end

%% Visualizations Functios 
%
% 1 - Originals
% 2 - Greyscale
% 3 - Pre Binarization Greyscale
% 4 - Binarized
% 5 - After Binarization
% 6 - Complement image
% 7 - Rotated imaged
%
function plotResults(cell, index)

    if  index < 1 || 8 < index
       index = 8;
    end    
    for i=1:length(cell(:,1))
        subplot(4,4,i), imshow(cell{i,3}{index})
        if index == 8
            plotProperties(cell{i,2});
        end
    end
end

function plotProcess(cell, index)

    if  index < 1 || length(cell(:,1)) < index
       index = 1;
    end
    steps = cell{index,3};
    props = cell{index,2};
    for i=1:length(steps)
        subplot(3,3,i), imshow(steps{i})
        if i == length(steps)
            plotProperties(props);
        end
    end
end

%
% Plots over the image the next properties, passed by parameter as a struct
% -Centroid
% -Bounding Box
% -Ellipse
%
function plotProperties(props)
    % Plot properties over the original image
    hold on

    % Centroid
    plot(props.Centroid(1,1),props.Centroid(1,2), 'b*')

    % Bounding Box
    rectangle('Position', props.BoundingBox, 'EdgeColor', 'red');

    % Elipse made with the minor and major axises
    plotElipse(props);
    
    % Extrema
    plot(props.Extrema(:,1), props.Extrema(:,2), 'om');

    hold off
end

% 
% Plots an ellipse given the struct returned by region props
% 
function plotElipse(s) 
    phi = linspace(0,2*pi,50);
    cosphi = cos(phi);
    sinphi = sin(phi);

    xbar = s.Centroid(1);
    ybar = s.Centroid(2);

    a = s.MajorAxisLength/2;
    b = s.MinorAxisLength/2;

    theta = pi*s.Orientation/180;
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];

    xy = [a*cosphi; b*sinphi];
    xy = R*xy;

    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;
    
    plot(x,y,'g','LineWidth',2)
end
