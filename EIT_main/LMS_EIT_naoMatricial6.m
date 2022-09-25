function [erro, X_out] = LMS_EIT_naoMatricial6(ImT,K,mu,Nx,Ny,kernel,ImAux,MascaraTemp,...
                                    utilizarPonderacao,imagens_reais,UV,estimate_motion,alg_index)
% 实现 LMS-SRR EIT 图像超分辨率
% IN: ImT   : 低分辨率断层图像
%     K     : R-LMS 算法每次即时迭代次数
%     mu    : LMS 算法步数大小
%     Nx,Ny : LR/IHR 图像的空间变暗素（以像素表示）
%     kernel: 模糊内核（用于去革命）
%     ImAux : 用于执行非统一向上/向下采样的辅助图像
%     MascaraTemp        : 包含 EIT 域中"1"值的指示器函数
%     utilizarPonderacao : 标记，设置为"1"，以给错误零权重EIT 图像域外的百分比
%     imagens_reais      : 真实图像（用于计算错误）
%     UV                 : 光学流场，设置为"[]"以使用注册算法
%     imagensRegistradas : 如果 IHR 图像已注册，则将标记设置为"1"事先 % 和 否则 "0"
% OUT: X    : 具有重建图像序列的细胞阵列
%      erro : 包含每个迭代的平均方形错误演化的阵列（仅在提供真实图像时计算）
%==========================================================================

%初始化平均方形错误向量
erro = zeros(1,length(ImT)*K);
l=0;

if alg_index ~= 1   &&   alg_index ~= 2   &&   alg_index ~= 3
    error('Wrong algorithm index!!')
end
% 以零初始化图像
X = zeros(Ny, Nx);
fprintf('\n\n')
%for t=1:(length(ImT)/10)
 for t=1:length(ImT)
    fprintf('Processing frame %d \n',t)
    for k=1:K
        xt1 = X;  % 图像初始化
        xt1 = imfilter(xt1,kernel,'symmetric','same');% 应用均匀和非统一（"三角形"）模糊
        % xt1 = imfilter(xt1,kernel,'same');
        xt1 = AplicaBlurDTri(xt1,ImT,t,ImAux);
        
        % 如有必要，应用掩码
        if utilizarPonderacao == 1
            xt1 = MascaraTemp.*xt1;
        end
        % ( y_d(t) - xt1(t) )
        xt1 = ImT(t).imagem{alg_index} - xt1;
            
        % 如有必要，应用掩码
        if utilizarPonderacao == 1
            xt1 = MascaraTemp.*xt1; % W_o*(LR - D*H*x)
        end

        % 应用换位均匀和非统一（"三角形"）模糊
        xt1 = AplicaBlurDTri(xt1,ImT,t,ImAux);
        xt1 = imfilter(xt1,kernel,'symmetric','same');
      % xt1 = imfilter(xt1,kernel,'same');
      % 应用提霍诺夫正规化
      % H_reg             = [1];
        H_reg             = fspecial('laplacian');
        alpha_lms_reg     = 0; % 使用未归化 LMS
        flag_imfilter_reg = 'circular';
        regul_lms_kf_tknv = 0;
        regul_lms_kf_tknv = imfilter(X, H_reg, flag_imfilter_reg, 'same');
        regul_lms_kf_tknv = imfilter(regul_lms_kf_tknv(end:-1:1, end:-1:1), H_reg, flag_imfilter_reg, 'same');
        regul_lms_kf_tknv = regul_lms_kf_tknv(end:-1:1, end:-1:1);
          
        % 如果可用人力资源图像，计算意味着方形错误
        l = l+1;
        if sum(size( imagens_reais(t).HR_uniform )) ~= 0 
            erro(l) = sum(sum( ( MascaraTemp.*X - MascaraTemp.*imagens_reais(t).imagem   ).^2 )) ;
        else
            erro(l) = 0;
        end
      % disp(l);
      % 更新重建图像
        X = X + mu * xt1   -   mu * alpha_lms_reg * regul_lms_kf_tknv;
        
    end
    % 存储输出图像
    X_out{t} = X;
    
    %在下一个瞬间之前执行图像录制
    %需要 +io 应用即时 t （当前） 亲
    %即时 t=1，在哪里比较 t+1 的 LR 图像（reg（i2，I1）
    if t < length(ImT)
        % 已知运动
        if estimate_motion == 0 && sum(size(UV)) ~= 0
          % vx = imresize(UV(t+1).vx,size(X),'bilinear');
          % vy = imresize(UV(t+1).vy,size(X),'bilinear');
            vx = UV(t+1).vx;
            vy = UV(t+1).vy;
        
        else % 估计运动   
          % uv = estimate_flow_hs(ImT(t+1).imagem, ImT(t).imagem,'pyramid_levels',4,'lambda',100);
            uv = estimate_flow_hs(ImT(t+1).imagem{alg_index}, ImT(t).imagem{alg_index},'pyramid_levels',4,'lambda',1e6); % 1e5 -- 1e15
          % uv = estimate_flow_hs(imagens_reais(t+1).imagem{alg_index}, imagens_reais(t).imagem{alg_index},'pyramid_levels',3,'lambda',1e5);
            vx = uv(:,:,1);
            vy = uv(:,:,2);          
            % 使用以下强制全部翻译运动
            % vx = ones(size(uv(:,:,1))) * mean(mean( uv(:,:,1) ));
            % vy = ones(size(uv(:,:,2))) * mean(mean( uv(:,:,2) ));
        end       
        % 扭曲估计图像
        X = warp_image(X, vx, vy, 2);
    end

    
end
