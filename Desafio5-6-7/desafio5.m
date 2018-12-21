%% Parámetros de configuración
folder = "C:\Users\Mikel\Pictures\coil-100";

clases = 100;         % Número de clases
theta = 0 ;           % angulo de la imagen rotada de 0 a 355  (para el colormap)
colores = 256;        % Colores del indexado
h = 128;              % Alto de las imagenes
w = 128;              % Ancho de las imagenes
angulos = [0,90,180,270]; % Representantes

%% Main
[muestra,I,mct] = calcularMapaDeColores(clases,theta,h,w,colores);

angulos_1 = [0];
reps_1 = calcularRepresentantes(clases,angulos_1, mct);
clasificacion_1 = clasificar(clases,reps_1,angulos_1,mct);
[confM_1,aciertos_1] = calcularResultados(clases,clasificacion_1);

%% Construir la muestra de colores
%%
%%
function [muestra,I,mct] = calcularMapaDeColores(clases,theta,h,w,colores)

    % Inicializamos la matriz que contendrá todas las imagenes de muestra y de
    % la que extraeremos el mapa de colores con el que trabajar.
    %
    %  *Concatenaremos las imagenes en la primera dimensión, por lo que los valores
    %   para la 2nda y la 3a dimensión se mantienen iguales.
    %
    muestra=uint8(zeros(h*clases,w,3));

    % Leemos las imagenes que tienen angulo Theta y creamos el mapa de colores
    % con ellas
    for i = 1:clases

        % Rellenamos la muestra
        imageName = "obj"+i+"__"+theta+".png";
        muestra((i-1)*h+1:i*h,1:w,1:3) = imread(imageName);
    end
    
    % Extracción del mapa de colores y muestra indexada a partir de la muestra
    [~,mct] = rgb2ind(muestra,colores);     
    I = rgb2ind(muestra,mct);     

end

% A partir de la muestra indexada, extracción de cada histograma de colores que
% en este caso serán de tamaño igual al mapa de colores (256)
% Matriz de celdas con los histogramas representantes de cada clase
function reps = calcularRepresentantes(clases,angulos, mct)
    reps = cell(clases*length(angulos),2);
    k = 1;
    % Para cada clase
    for i=1:clases
        % Para cada angulo en angulos de cada clase
        for j = 1:length(angulos)
            imageName = "obj"+i+"__"+angulos(j)+".png";
            [contadores,~]=imhist(rgb2ind(imread(imageName),mct),mct);
            reps(k,1:2)={i,contadores};
            k=k+1;
        end 
    end
end

%% Clasificación de las imagenes
% En este punto todos los representantes están creados y almacenados, ahora
% clasificamos el resto de las imagenes en función del valor de la norma
% para con cada representante, clasificando cada imagen como aquella con
% las menor distancia euclidea.
function clasificacion = clasificar(clases,reps,angulos,mct)

    % Matriz de pares con el numero de clase real y clasificado
    clasificacion = zeros(clases*(72 - length(angulos)),1);
    
    % Para cada clase de 1 a 100
    j = 1;
    for i = 1:clases
        % Para cada angulo de 0 a 355 (de 5 en 5 grados)
        for theta = 0:5:355
            if ~ismember(theta,angulos)
                imageName = "obj"+i+"__"+theta+".png";

                % Indexar y sacar el histograma
                indexada = rgb2ind(imread(imageName),mct);
                [contadores,~]=imhist(indexada,mct);

                % Clasificar
                clase = NN_1(reps,contadores);

                clasificacion(j,1:2) = [i, clase];
                j = j+1;
            end
        end 
    end
end

% NN_1 
%   
% reps -> lista de ( clase, histograma)
% aClasificar -> histograma
%
% returns clase de mínima norma
%
function clase = NN_1(reps, aClasificar)
    
    min = intmax();
    clase = 0;
    
    for i = 1:length(reps)
        clase_temp = reps{i,1};
        hist = reps{i,2};
        norma = norm(hist-aClasificar);
        
        if norma < min 
            clase = clase_temp;
            min = norma;
        end 
    end
end

%% Extracción de resultados de la clasificación 
%
%
%
function [confM,aciertos] = calcularResultados(clases, clasificacion)
    confM = zeros(clases,clases);
    aciertos = 0;
    for i = 1:length(clasificacion)
        real = clasificacion(i,1); % Clase real
        clas = clasificacion(i,2); % Clase clasificada
        
        confM(real,clas) = confM(real,clas) + 1;
        
       if real == clas 
           aciertos = aciertos +1;
       end
    end
    
    aciertos = aciertos/length(clasificacion);
end

