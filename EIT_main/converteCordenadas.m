function [imagens_reais,ImT] = converteCordenadas(imagens_reais,imagens_eit)
for t=1:length(imagens_eit)
    % 初始化坐标向量
    ImT(t).coord.x = zeros(length(imagens_eit(1).faces),3);
    ImT(t).coord.y = zeros(length(imagens_eit(1).faces),3);
    
    % 分配电阻值
  % ImT(t).coord.value = imagens_eit(t).cdata;
    ImT(t).coord.value_LR    = imagens_eit(t).cdata_LR;
    
    % 对于每个图像，找到坐标
    % elemento/faces = [vertice1 vertice2 vertice3]
    % vertice = x1 y1 (do vertice indice)
    for i=1:length(imagens_eit(t).faces)
        ImT(t).coord.x(i,:) = [imagens_eit(t).vertices(imagens_eit(t).faces(i,1),1) ...
                               imagens_eit(t).vertices(imagens_eit(t).faces(i,2),1) imagens_eit(t).vertices(imagens_eit(t).faces(i,3),1)]; 
        ImT(t).coord.y(i,:) = [imagens_eit(t).vertices(imagens_eit(t).faces(i,1),2) ...
                               imagens_eit(t).vertices(imagens_eit(t).faces(i,2),2) imagens_eit(t).vertices(imagens_eit(t).faces(i,3),2)];
    end
    
    
    % 重复真实图像（如果可用）
    if sum(size(imagens_reais(1))) ~= 0 
        for i=1:length(imagens_reais(t).faces)
            imagens_reais(t).coord.x(i,:) = [ imagens_reais(t).vertices(imagens_reais(t).faces(i,1),1) ...
                                              imagens_reais(t).vertices(imagens_reais(t).faces(i,2),1) ...
                                              imagens_reais(t).vertices(imagens_reais(t).faces(i,3),1) ]; 
            imagens_reais(t).coord.y(i,:) = [ imagens_reais(t).vertices(imagens_reais(t).faces(i,1),2) ...
                                              imagens_reais(t).vertices(imagens_reais(t).faces(i,2),2) ...
                                              imagens_reais(t).vertices(imagens_reais(t).faces(i,3),2) ];
        end
        imagens_reais(t).coord.value = imagens_reais(t).cdata;
    end
    
end
