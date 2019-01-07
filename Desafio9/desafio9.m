disparityRange = [0 32];
blockSize = 5;

% Lectura de las imágenes
folder = "C:\Users\Mikel\Dropbox\docencia vision 2018\alumnos\DALMAU CHERINO MIKEL\Desafio9\";
series = ["barn1"  "barn2"  "bull"  "venus" "poster" "sawtooth"];
for s = 1:length(series)
    I1 = rgb2gray(imread(series(s) + "/im0.ppm"));
    I2 = rgb2gray(imread(series(s) + "/im4.ppm"));
    GT = imread(series(s) + "/disp6.pgm");
    ims(s,:) = {I1, I2, GT};
end

% % Calcular las disparidades entre cada par de imágenes distintas
% for i = 1: length(images)
%     for j = i:length(images)
%         if i ~= j 
%             disparityMaps(i,j) = {disparity(images{i},images{j},'BlockSize',5,'DisparityRange',disparityRange)};
%         end
%     end
% end
for i = 1: length(ims)
  dM = disparity(ims{i,1},ims{i,2},'BlockSize',5,'DisparityRange',disparityRange);
  errors(i) = calculateErrorRate(uint8(dM),ims{i,3}/8);
end
            
bar(series, errors);
function errorRate = calculateErrorRate(I1, gt)
    tot = 0;
    err = 0;
    for i = 1:length(I1(:,1))
        for j = 1:length(I1)
            if I1(i,j) ~= 0
                if abs(I1(i,j) - gt(i,j)) > 1
                    err = err + 1;
                end
                tot = tot + 1;
            end
        end
    end
    errorRate = (err / tot) * 100;
end
