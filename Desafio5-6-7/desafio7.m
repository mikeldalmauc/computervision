clases = 100;         % Número de clases
h = 128;              % Alto de las imagenes
w = 128;              % Ancho de las imagenes
angulos = [0,90,180,270];        % Que imagenes van a usarse para el entrenamiento
 
% Cargar todas las imágenes para reducir operaciones I/O y tiempo de ejec.
coil_100 = loadCoilDatabase();
 
% Extrae las características de las imágnes 
trainedFeatures = extractTrainFeatures(coil_100,angulos,h,w);

% Matriz de confusión
confM = zeros(100); 

for j = 1:72
    % Creo la escena de imágenes y la de sus clases correspondientes
    [escena,matrizClases] = crearEscena(coil_100,j, h, w);

    % Extraigo las características SURF (Speeded-Up Robust Features algorithm)
    % de la escena
    escenaGS = rgb2gray(escena);
    pointsEscena = detectSURFFeatures(escenaGS);
    [featuresEscena,validPointsEscena] = extractFeatures(escenaGS,pointsEscena);

    % Busco cada imagen en la escena usando las características entrenadas
    % al principio
    clasificacion = zeros(100,2);
    for i = 1:100
        real = i;
        class = clasificarImagen(trainedFeatures{i}, featuresEscena, validPointsEscena, matrizClases);
        
        confM(real,class) = confM(real,class) + 1;
    end    
end

%% 
% Crea a partir de las imagenes  una lista de características que luego se
% van a utilizar para encontrarlas en las escenas
%
function trainedFeatures = extractTrainFeatures(coil_100,angulos,h,w)
    trainedFeatures = cell(100,1);
    for i=1:100
        I = crearImagenDeEntrenamiento(coil_100, i, angulos,h,w);
       
        IG = rgb2gray(I);
        points = detectSURFFeatures(IG);
        [features,~] = extractFeatures(IG,points);
        trainedFeatures(i) = {features};
    end
end


%% Clasificar imágenes
%%
function clase = clasificarImagen(features, featuresEscena, validPointsEscena, matrizClases)
    
    % Buscar coincidencias entre las características
    indexPairs = matchFeatures(featuresEscena,features) ;

    % Extraer puntos de la escena que han coincididio
    matchedPointsEscena = validPointsEscena(indexPairs(:,1));
    
    % Buscar en la matriz de clases los puntos que han coincidido y extraer
    % las clases
    clases = zeros([matchedPointsEscena.Count 1]);
    locations = matchedPointsEscena.Location;
    for i = 1:matchedPointsEscena.Count
        clases(i) = matrizClases(floor(locations(i,2)),floor(locations(i,1)));
    end     
    
    % Elegir la calse más frecuente como la clasificada
    clase = mode(clases);
   
    if isnan(clase)
        clase = 1;
    end
end

%% Crear Escena
% Une todas las imágenes de coil-100 para un àngulo theta en una imágen de
% 10 x 10 imágenes.
%
% Crea una imágen equivalente donde cada coordenada tiene la clase
% perteneciente asociada.
%
% Muestra de imágenes 
function [muestra,matrizClases] = crearEscena(coil_100,theta,h,w)

    % Inicializamos la matriz que contendrá todas las imagenes de muestra
    muestra=uint8(zeros(h*10,w*10,3));
    matrizClases = uint8(zeros(h*10,w*10));
    
    % Leemos las imagenes que tienen angulo Theta y creamos la escena con
    % ellas
    for i = 1:100
        
        % Calculamos los índices en los que se insertará la imagen
        [Q,R] = quorem(sym(i),sym(10));
        if R == 0
            R = 10;
            Q = Q - 1;
        end
        x = Q*h+1;
        x2 = (Q+1)*h;
        y = (R-1)*w + 1;
        y2 = R*w;
        
        % Añadimos la imagen a la escena y la clase a la matriz de clases
        muestra(x:x2,y:y2,1:3) = coil_100{i,theta};
        matrizClases(x:x2,y:y2) = i;
    end
end

%% Crea una union de imagenes 
%   
%
function I = crearImagenDeEntrenamiento(coil_100, clase, angulos,h,w)
    
    I=uint8(zeros(h*length(angulos),w,3));
    for i = 1:length(angulos)
        I((i-1)*h+1:i*h,1:w,1:3) = coil_100{clase,angulos(i)/5 + 1};
    end 
end

%% Carga todas las imagenes de coil
function coil_100 = loadCoilDatabase()
    coil_100 = cell(100,72); 
    for i = 1:100
        for j = 0:5:355
            coil_100(i,j/5+1) = {imread("obj"+i+"__"+j+".png")};
        end
    end
end