function [X2] = AplicaBlurDTri(X,ImT,t,ImAux)
% ���� Imt ��t. coord�� ��ͼ��Ӧ�÷�ͳһģ��
X2 = X;
for i=1:length(ImT(t).coord.x)
    % ����Ԫ�� i �е�λ��
    temp = inpolygon(ImAux.X,ImAux.Y,ImT(t).coord.x(i,:),ImT(t).coord.y(i,:));
    % ��ȡ����Ԫ�ص�����ָ��
    [rowi coli] = find(temp); % ��������Щ�������Ԫ�� i ������ 0��
    % ��ʼ���������µļ�ֵ����
    valorMedio = 0;
    % ����Ԫ�����ص���Сֵ���¶�Ϊ����⣩
    for k=1:length(rowi)
        valorMedio = valorMedio + X(rowi(k),coli(k))/length(rowi);
    end
    % ����Ԫ�����صļ�ֵ����ǰ���֣�
    for k=1:length(rowi)
        X2(rowi(k),coli(k)) = valorMedio;
    end

end
