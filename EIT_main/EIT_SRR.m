

function [srr_ims,MALHA,ImT]=EIT_SRR(imgn_lr,Nx,Ny)
% ---------------------------------------------------------------------------
% 执行电阻抗的超分辨率重建 （SRR）
% INPUTS:--输入:
%         imgn_lr : structure containing the LR images in EIDORS format, --包含 EIDORS 格式中的 LR 图像的结构，
%                   with fields --带字段的百分比：
%                   - fwd_model.elems: array containing the elements --包含元素的阵列
%                   - imgn_lr.fwd_model.nodes: array with the nodes --带节点的阵列
%                   - imgn_lr.elem_data(:,t): electrodes * T array with
%                   voltage --电极 * 带电压的 T 阵列
%                                             measurements for each time
%                                             instant --每次即时测量
%         Nx, Ny  : width/height of the IHR/HR image in pixels --像素 IHR/HR 图像的宽度/高度
% 
% OUTPUTS:--输出：
%                   在统一网格中包含超分辨率图像的单元序列
%         srr_ims : cell array containing the super-resolved images, in an uniform grid 
%         MALHA   : structure containing data used for plotting the images
%         --包含用于绘制图像的数据的结构
%         ImT     : structure containing the low-resolution images --包含低分辨率图像的结构
% ---------------------------------------------------------------------------


% add registration algorithm to path --将注册算法添加到路径
addpath(genpath('hs'));


% ---------------------------------------------------------------------------
% convert to new format --转换为新格式

% number of frames --帧数
% T = size(imgn_lr.elem_data,2);
[~,T] = size(imgn_lr.elem_data);

% Load HR images --加载HR图像  
for t=1:T
    imagens_reais(t).faces      = [];
    imagens_reais(t).vertices   = [];
    imagens_reais(t).cdata      = [];
    imagens_reais(t).faceColor  = [];
    imagens_reais(t).HR_uniform = [];
end

% Convert  LR images --转换为LR图像
for t=1:T
    imagens_eit(t).faces     = imgn_lr.fwd_model.elems;
    imagens_eit(t).vertices  = imgn_lr.fwd_model.nodes;
    imagens_eit(t).cdata_LR  = imgn_lr.elem_data(:,t);
    imagens_eit(t).faceColor = 'flat';
end
%从元素表面去除颜色，以便仅绘制网格
% Remove color from the elements face in order to plot only the mesh grid
for t=1:length(imagens_eit)
    imagens_eit(t).faceColor = 'none';
end

% Images are NOT registered beforehand: --未事先注册图像：
UV = []; 
imagensRegistradas = false;





% ---------------------------------------------------------------------------
% Apply pre-processing --应用预处理

%==========================================================================
%                               选项                                      %
%============================== OPTIONS ===================================
%                                                                         %
%将 LR 图像正常化到 [0，255] 范围？
% Normalize the LR images to the [0,255] range?
normalizarImagens = 0; % 1 --> yes  | 0 --> no


%==========================================================================
%                            转换图像                                            %
%========================= CONVERT THE IMAGES =============================
%                                                                         %
% originail data:
%与矢量索引对应的元素中的电导率值
% im.cdata   : conductivity value in the elements corresponding to the vector indexes
% 每行包含构成给定元素的 3 个顶点索引
%im.faces   : each line contains 3 indexes of the vertices that compose a given element
% 网格中所有现有顶点的坐标
%im.vertices: coordinates of all existing vertices in the mesh
%将 LR 图像转换为格式：元素 #;x1，2，3;x1，2，3;数值
% Converts the LR images to the format:   element #; x1,2,3; x1,2,3; value 
[imagens_reais,ImT] = converteCordenadas(imagens_reais,imagens_eit);

%==========================================================================
%                               使用像素位置创建辅助矩阵                                          %
%======== CREATES AUXILIARY MATRICES WITH PIXEL POSITIONS =================
% 使用与统一网格中的像素对应的 （x，y） 位置创建辅助矩阵                                                                        %
% Creates auxiliary matrices with the (x,y) positions corresponding to the
% pixels in the uniform grid

[ImAux] = criaMatrizesAux_comPosicao_dosPixels(ImT(1).coord, Nx, Ny);


%==========================================================================
%                            克里娅图像 EM 级制服 （IHR）                                             %
%================= CRIA IMAGENS EM GRADE UNIFORME (IHR) ===================
%                             将 EIT 图像重新采样到制服 （IHR） 网格                                            %
% Returns the EIT images resampled to the uniform (IHR) grid
[ImT,imagens_reais,MascaraTemp] = reamostraTIE_uniforme(ImT,imagens_reais,normalizarImagens,Nx,Ny,ImAux);


% throw all images into a single cell array: --将所有图像放入单个单元格阵列：
for t=1:length(ImT)
    ImT(t).imagem{1} = ImT(t).imagem_LR;
end




%
%==========================================================================
%                           执行超分辨率与 LMS-SRR-EIT                                              %
%============= PERFORMS SUPER RESOLUTION WITH LMS-SRR-EIT =================
%                                                                         %

% LMS-SRR parameters --LMS-SRR 参数
K  = 100;
mu = 0.01;
kernel = fspecial('gaussian',60,20);
utilizarPonderacao = 0; % do not weight the error according to the domain
%不要根据域对错误进行加权

estimate_motion = 1;
alg_index = 1;
[erro,X_rec] = LMS_EIT_naoMatricial6(ImT,K,mu,Nx,Ny,kernel,ImAux,MascaraTemp,...
                                   utilizarPonderacao,imagens_reais,UV,estimate_motion,alg_index);

% attribute reconstructed image --重建图像属性
srr_ims = X_rec;





% compute a structure used for ploting the FEM over the images
%计算用于在图像上绘制 FEM 的结构
[num_measurents,~] = size(ImT(1).coord.x);

% instantiate mesh --瞬间网格
clear MALHA
MALHA.coord.x = ImT(1).coord.x;
MALHA.coord.y = ImT(1).coord.y;
MALHA.cdata   = zeros(num_measurents,1);
% Soma valor para deslocar o centro da malha do zero, deixando-a no primeiro quadrante
MALHA.coord.x = MALHA.coord.x + max(MALHA.coord.x(:)) + (2/Nx); %+ max(max(MALHA.coord.x))*ones(length(MALHA.coord.x),3) + (1/Nx);
MALHA.coord.y = MALHA.coord.y + max(MALHA.coord.y(:)) + (2/Ny);
% Muda a escala da malha para ficar do mesmo tamanho do que a imagem
MALHA.coord.x = MALHA.coord.x*(Nx-(1))/max(MALHA.coord.x(:));
MALHA.coord.y = MALHA.coord.y*(Ny-(1))/max(MALHA.coord.y(:));





