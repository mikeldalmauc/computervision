function showFilteredImg(gaborArray, gaborMag)
    figure
    len = length(gaborArray);
    h = sqrt(len);
    subplot(h,h,1);
    for p = 1:len
        subplot(h,h,p)
        imshow(gaborMag(:,:,p),[]);
        theta = gaborArray(p).Orientation;
        lambda = gaborArray(p).Wavelength;
        title(sprintf('Orientation=%d, Wavelength=%d',theta,lambda));
    end
end