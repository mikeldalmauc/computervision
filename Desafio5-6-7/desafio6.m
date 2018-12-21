
%% Leer los datos
caracteristicas = cell(100,72);
for obj=1:100
    for vista = 1:72
        imageName = "obj"+obj+"__"+(5*(vista-1))+".png";
        caracteristicas{obj,vista}=extractHOGFeatures(imread(imageName),'CellSize',[32, 32]);
    end
end

%%

confusion=zeros(100);

vistasTestSize = 8;
shift = 72/vistasTestSize;
for i=1:shift
    vistas_train = i:shift:i+(vistasTestSize-1)*shift;
    for vista_test=1:72
        if ~ismember(vista_test,vistas_train)
            for obj_test=1:100
                dist=[100*length(vistas_train) 2];
                
                k = 1;
                for obj_train=1:100
                    for j = 1:length(vistas_train)
                        dist(k,:)=[obj_train, norm(caracteristicas{obj_train,vistas_train(j)}-caracteristicas{obj_test,vista_test})];
                        k = k + 1;
                    end
                end

                [m,obj_m]=min(dist(:,2));
                obj_min = dist(obj_m,1);
                confusion(obj_test,obj_min)=confusion(obj_test,obj_min)+1;
            end
        end
    end
end



