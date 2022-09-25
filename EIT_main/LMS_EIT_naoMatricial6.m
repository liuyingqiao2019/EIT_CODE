function [erro, X_out] = LMS_EIT_naoMatricial6(ImT,K,mu,Nx,Ny,kernel,ImAux,MascaraTemp,...
                                    utilizarPonderacao,imagens_reais,UV,estimate_motion,alg_index)
% ʵ�� LMS-SRR EIT ͼ�񳬷ֱ���
% IN: ImT   : �ͷֱ��ʶϲ�ͼ��
%     K     : R-LMS �㷨ÿ�μ�ʱ��������
%     mu    : LMS �㷨������С
%     Nx,Ny : LR/IHR ͼ��Ŀռ�䰵�أ������ر�ʾ��
%     kernel: ģ���ںˣ�����ȥ������
%     ImAux : ����ִ�з�ͳһ����/���²����ĸ���ͼ��
%     MascaraTemp        : ���� EIT ����"1"ֵ��ָʾ������
%     utilizarPonderacao : ��ǣ�����Ϊ"1"���Ը�������Ȩ��EIT ͼ������İٷֱ�
%     imagens_reais      : ��ʵͼ�����ڼ������
%     UV                 : ��ѧ����������Ϊ"[]"��ʹ��ע���㷨
%     imagensRegistradas : ��� IHR ͼ����ע�ᣬ�򽫱������Ϊ"1"���� % �� ���� "0"
% OUT: X    : �����ؽ�ͼ�����е�ϸ������
%      erro : ����ÿ��������ƽ�����δ����ݻ������У������ṩ��ʵͼ��ʱ���㣩
%==========================================================================

%��ʼ��ƽ�����δ�������
erro = zeros(1,length(ImT)*K);
l=0;

if alg_index ~= 1   &&   alg_index ~= 2   &&   alg_index ~= 3
    error('Wrong algorithm index!!')
end
% �����ʼ��ͼ��
X = zeros(Ny, Nx);
fprintf('\n\n')
%for t=1:(length(ImT)/10)
 for t=1:length(ImT)
    fprintf('Processing frame %d \n',t)
    for k=1:K
        xt1 = X;  % ͼ���ʼ��
        xt1 = imfilter(xt1,kernel,'symmetric','same');% Ӧ�þ��Ⱥͷ�ͳһ��"������"��ģ��
        % xt1 = imfilter(xt1,kernel,'same');
        xt1 = AplicaBlurDTri(xt1,ImT,t,ImAux);
        
        % ���б�Ҫ��Ӧ������
        if utilizarPonderacao == 1
            xt1 = MascaraTemp.*xt1;
        end
        % ( y_d(t) - xt1(t) )
        xt1 = ImT(t).imagem{alg_index} - xt1;
            
        % ���б�Ҫ��Ӧ������
        if utilizarPonderacao == 1
            xt1 = MascaraTemp.*xt1; % W_o*(LR - D*H*x)
        end

        % Ӧ�û�λ���Ⱥͷ�ͳһ��"������"��ģ��
        xt1 = AplicaBlurDTri(xt1,ImT,t,ImAux);
        xt1 = imfilter(xt1,kernel,'symmetric','same');
      % xt1 = imfilter(xt1,kernel,'same');
      % Ӧ�����ŵ�����滯
      % H_reg             = [1];
        H_reg             = fspecial('laplacian');
        alpha_lms_reg     = 0; % ʹ��δ�黯 LMS
        flag_imfilter_reg = 'circular';
        regul_lms_kf_tknv = 0;
        regul_lms_kf_tknv = imfilter(X, H_reg, flag_imfilter_reg, 'same');
        regul_lms_kf_tknv = imfilter(regul_lms_kf_tknv(end:-1:1, end:-1:1), H_reg, flag_imfilter_reg, 'same');
        regul_lms_kf_tknv = regul_lms_kf_tknv(end:-1:1, end:-1:1);
          
        % �������������Դͼ�񣬼�����ζ�ŷ��δ���
        l = l+1;
        if sum(size( imagens_reais(t).HR_uniform )) ~= 0 
            erro(l) = sum(sum( ( MascaraTemp.*X - MascaraTemp.*imagens_reais(t).imagem   ).^2 )) ;
        else
            erro(l) = 0;
        end
      % disp(l);
      % �����ؽ�ͼ��
        X = X + mu * xt1   -   mu * alpha_lms_reg * regul_lms_kf_tknv;
        
    end
    % �洢���ͼ��
    X_out{t} = X;
    
    %����һ��˲��֮ǰִ��ͼ��¼��
    %��Ҫ +io Ӧ�ü�ʱ t ����ǰ�� ��
    %��ʱ t=1��������Ƚ� t+1 �� LR ͼ��reg��i2��I1��
    if t < length(ImT)
        % ��֪�˶�
        if estimate_motion == 0 && sum(size(UV)) ~= 0
          % vx = imresize(UV(t+1).vx,size(X),'bilinear');
          % vy = imresize(UV(t+1).vy,size(X),'bilinear');
            vx = UV(t+1).vx;
            vy = UV(t+1).vy;
        
        else % �����˶�   
          % uv = estimate_flow_hs(ImT(t+1).imagem, ImT(t).imagem,'pyramid_levels',4,'lambda',100);
            uv = estimate_flow_hs(ImT(t+1).imagem{alg_index}, ImT(t).imagem{alg_index},'pyramid_levels',4,'lambda',1e6); % 1e5 -- 1e15
          % uv = estimate_flow_hs(imagens_reais(t+1).imagem{alg_index}, imagens_reais(t).imagem{alg_index},'pyramid_levels',3,'lambda',1e5);
            vx = uv(:,:,1);
            vy = uv(:,:,2);          
            % ʹ������ǿ��ȫ�������˶�
            % vx = ones(size(uv(:,:,1))) * mean(mean( uv(:,:,1) ));
            % vy = ones(size(uv(:,:,2))) * mean(mean( uv(:,:,2) ));
        end       
        % Ť������ͼ��
        X = warp_image(X, vx, vy, 2);
    end

    
end
