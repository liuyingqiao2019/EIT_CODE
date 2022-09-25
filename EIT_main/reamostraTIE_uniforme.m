function [ImT,imagens_reais,MascaraTemp] = reamostraTIE_uniforme(ImT,imagens_reais,normalizarImagens,Nx,Ny,ImAux)
% 将 EIT 图像重新调整到空间均匀的网格（IHR 图像）
for i=1:length(ImT)
    ImT(i).imagem_LR = zeros(Ny,Nx);
end

% 为实际图像创建相同的字段
if sum(size( imagens_reais(1) )) ~= 0 
    imagem_real(length(imagens_reais)).imagem = zeros(Ny, Nx);
end

% LR 的重新采样
for j=1:length(ImT)
    for i=1:length(ImT(j).coord.x)
        temp = inpolygon(ImAux.X,ImAux.Y,ImT(j).coord.x(i,:),ImT(j).coord.y(i,:)); % 查找元素i
        temp = temp*ImT(j).coord.value_LR(i);% 分配元素的位置值
        % 不加倍分配任何像素，若像素已被分配了值，则将其删除
        temp = (ImT(j).imagem_LR == 0) .* temp;
        ImT(j).imagem_LR = ImT(j).imagem_LR + temp;
    end
    % 降低零到零以外的最低值（正常化），只有 v +++元素，无视零
    [linhas, colunas] = find(ImT(j).imagem_LR); % 等于零的元素指数
    temp = sparse(linhas,colunas,ones(length(linhas),1),Nx,Ny);
    temp = full(temp); % 转换为正常/完整阵列
    MascaraTemp = temp; % 存储 m+++卡拉供以后使用
    
    % 显示生成的掩码
    if normalizarImagens == 1
        ValMin = min(nonzeros(ImT(j).imagem_LR)); % 低于零的最低 Im 值
        ValMax = max(nonzeros(ImT(j).imagem_LR));
        temp = temp*ValMin;
        ImT(j).imagem_LR = ImT(j).imagem_LR - temp;
        ImT(j).imagem_LR = ImT(j).imagem_LR*floor(255/(ValMax-ValMin));
    end
    
end
