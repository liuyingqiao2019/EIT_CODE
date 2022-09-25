function [srr_ims,MALHA,ImT,scs_name]=EIT_ESPCN(imgn_lr,Nx,Ny)
%% 设置
model = 'ESPCN/ESPCN_mat.prototxt';
weights = 'ESPCN/snapshot/espcn_iter_1000.caffemodel';
batch = 1;
up_scale = 3;

%% 导入数据
input = imread('../Data/original.png');
% if size(input,3)>1
    input2 = rgb2ycbcr(input);% RGB转Ycbcr
    input = input2(:,:, 1);
    im_l_cb = input2(:,:, 2);
    im_l_cr = input2(:,:, 3);
% end;
input = single(input)/255;

% 降低图像分辨率,像素值取4-邻域中的加权平均值
input = imresize(input, 1/up_scale, 'bicubic');
[height, width, channel] = size(input);

%% caffe使用cpu加速
caffe.reset_all(); 
caffe.set_mode_cpu();% 清除所有solvers和生成的nets

%% 加载mat_caffe模型
net = caffe.Net(model,weights,'test');% 创建网络并载入权重
net.blobs('data').reshape([height width channel batch]); 
net.reshape();% 一次运行一张图片
net.blobs('data').set_data(input);% 用input填充blob ‘data’
net.forward_prefilled();% 使用input blobs(s)已经存在的数据进行前向计算
output = net.blobs('conv3').get_data();% 从内部blobs中提取conv3层的特征
[output_height, output_width, output_channel] = size(output);% 获取图片的尺寸、通道
scaled_height = up_scale * output_height;
scaled_width = up_scale * output_width;
im_h = zeros(scaled_height, scaled_width);

% 低分辨率图层上进行卷积操作
for m = 1 : up_scale
     for n = 1 : up_scale
         im_h(m:up_scale:scaled_height+m-up_scale,n:up_scale:scaled_width+n-up_scale) = output(:,:,(m-1)*up_scale+n);   
     end
end
im_h = im_h * 255;
[nrow, ncol] = size(im_h);
im_h_cb = imresize(im_l_cb, [nrow, ncol], 'bicubic');
im_h_cr = imresize(im_l_cr, [nrow, ncol], 'bicubic');

im_h_ycbcr = zeros([nrow, ncol, 3]);
im_h_ycbcr(:, :, 1) = im_h;
im_h_ycbcr(:, :, 2) = im_h_cb;
im_h_ycbcr(:, :, 3) = im_h_cr;
% [height, width, channel] = size(im_h);
im_h = ycbcr2rgb(uint8(im_h_ycbcr));
% im_h = uint8(im_h * 255);

imwrite(im_h,'ESPCN/result/espcn_caffe.bmp');

scs_name = 'espcn_caffe';
addpath(genpath('hs'));
[~,T] = size(imgn_lr.elem_data);

% 加载HR图像  
for t=1:T
    imagens_reais(t).faces      = [];
    imagens_reais(t).vertices   = [];
    imagens_reais(t).cdata      = [];
    imagens_reais(t).faceColor  = [];
    imagens_reais(t).HR_uniform = [];
end

% 转换为LR图像
for t=1:T
    imagens_eit(t).faces     = imgn_lr.fwd_model.elems;
    imagens_eit(t).vertices  = imgn_lr.fwd_model.nodes;
    imagens_eit(t).cdata_LR  = imgn_lr.elem_data(:,t);
    imagens_eit(t).faceColor = 'flat';
end

% 从元素表面去除颜色，以便仅绘制网格
for t=1:length(imagens_eit)
    imagens_eit(t).faceColor = 'none';
end

% 未事先注册图像：
UV = []; 
imagensRegistradas = false;

                                                                        
% 将 LR 图像正常化到 [0，255] 范围？
normalizarImagens = 0; % 1 --> yes  | 0 --> no

%% 转换图像                                                                                                                   
% im.cdata   : %与矢量索引对应的元素中的电导率值
% im.faces   :  % 每行包含构成给定元素的 3 个顶点索引
% im.vertices: % 网格中所有现有顶点的坐标
[imagens_reais,ImT] = converteCordenadas(imagens_reais,imagens_eit);% 将 LR 图像转换为格式：元素 #;x1，2，3;x1，2，3;数值

%% 使用像素位置创建辅助矩阵                                          
% 使用与统一网格中的像素对应的 （x，y） 位置创建辅助矩阵                                                                        
[ImAux] = criaMatrizesAux_comPosicao_dosPixels(ImT(1).coord, Nx, Ny);

% 将 EIT 图像重新采样到制服 （IHR） 网格                                            
[ImT,imagens_reais,MascaraTemp] = reamostraTIE_uniforme(ImT,imagens_reais,normalizarImagens,Nx,Ny,ImAux);

% 将所有图像放入单个单元格阵列：
for t=1:length(ImT)
    ImT(t).imagem{1} = ImT(t).imagem_LR;
end

%% 执行超分辨率与 LMS-SRR-EIT                                              
% LMS-SRR 参数
K  = 100;
mu = 0.01;
kernel = fspecial('gaussian',60,20);
utilizarPonderacao = 0; % 不要根据域对错误进行加权
estimate_motion = 1;
alg_index = 1;
[erro,X_rec] = LMS_EIT_naoMatricial6(ImT,K,mu,Nx,Ny,kernel,ImAux,MascaraTemp,...
                                   utilizarPonderacao,imagens_reais,UV,estimate_motion,alg_index);
srr_ims = X_rec;% 重建图像属性
[num_measurents,~] = size(ImT(1).coord.x);% 计算用于在图像上绘制 FEM 的结构

% 瞬间网格
clear MALHA
MALHA.coord.x = ImT(1).coord.x;
MALHA.coord.y = ImT(1).coord.y;
MALHA.cdata   = zeros(num_measurents,1);
MALHA.coord.x = MALHA.coord.x + max(MALHA.coord.x(:)) + (2/Nx); %+ max(max(MALHA.coord.x))*ones(length(MALHA.coord.x),3) + (1/Nx);
MALHA.coord.y = MALHA.coord.y + max(MALHA.coord.y(:)) + (2/Ny);
MALHA.coord.x = MALHA.coord.x*(Nx-(1))/max(MALHA.coord.x(:));
MALHA.coord.y = MALHA.coord.y*(Ny-(1))/max(MALHA.coord.y(:));

