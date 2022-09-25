function [ImT,imagens_reais,MascaraTemp] = reamostraTIE_uniforme(ImT,imagens_reais,normalizarImagens,Nx,Ny,ImAux)
% �� EIT ͼ�����µ������ռ���ȵ�����IHR ͼ��
for i=1:length(ImT)
    ImT(i).imagem_LR = zeros(Ny,Nx);
end

% Ϊʵ��ͼ�񴴽���ͬ���ֶ�
if sum(size( imagens_reais(1) )) ~= 0 
    imagem_real(length(imagens_reais)).imagem = zeros(Ny, Nx);
end

% LR �����²���
for j=1:length(ImT)
    for i=1:length(ImT(j).coord.x)
        temp = inpolygon(ImAux.X,ImAux.Y,ImT(j).coord.x(i,:),ImT(j).coord.y(i,:)); % ����Ԫ��i
        temp = temp*ImT(j).coord.value_LR(i);% ����Ԫ�ص�λ��ֵ
        % ���ӱ������κ����أ��������ѱ�������ֵ������ɾ��
        temp = (ImT(j).imagem_LR == 0) .* temp;
        ImT(j).imagem_LR = ImT(j).imagem_LR + temp;
    end
    % �����㵽����������ֵ������������ֻ�� v +++Ԫ�أ�������
    [linhas, colunas] = find(ImT(j).imagem_LR); % �������Ԫ��ָ��
    temp = sparse(linhas,colunas,ones(length(linhas),1),Nx,Ny);
    temp = full(temp); % ת��Ϊ����/��������
    MascaraTemp = temp; % �洢 m+++�������Ժ�ʹ��
    
    % ��ʾ���ɵ�����
    if normalizarImagens == 1
        ValMin = min(nonzeros(ImT(j).imagem_LR)); % ���������� Im ֵ
        ValMax = max(nonzeros(ImT(j).imagem_LR));
        temp = temp*ValMin;
        ImT(j).imagem_LR = ImT(j).imagem_LR - temp;
        ImT(j).imagem_LR = ImT(j).imagem_LR*floor(255/(ValMax-ValMin));
    end
    
end
