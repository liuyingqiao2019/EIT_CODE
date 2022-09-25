function [X2] = AplicaBlurDTri(X,ImT,t,ImAux)
% 根据 Imt （t. coord） 对图像应用非统一模糊
X2 = X;
for i=1:length(ImT(t).coord.x)
    % 查找元素 i 中的位置
    temp = inpolygon(ImAux.X,ImAux.Y,ImT(t).coord.x(i,:),ImT(t).coord.y(i,:));
    % 获取属于元素的像素指数
    [rowi coli] = find(temp); % 我们有哪些像素组成元素 i （除了 0）
    % 初始化三重奏下的价值古洛
    valorMedio = 0;
    % 计算元素像素的最小值（温度为零除外）
    for k=1:length(rowi)
        valorMedio = valorMedio + X(rowi(k),coli(k))/length(rowi);
    end
    % 分配元素像素的价值（以前发现）
    for k=1:length(rowi)
        X2(rowi(k),coli(k)) = valorMedio;
    end

end
