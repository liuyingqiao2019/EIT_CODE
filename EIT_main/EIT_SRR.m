

function [srr_ims,MALHA,ImT]=EIT_SRR(imgn_lr,Nx,Ny)
% ---------------------------------------------------------------------------
% ִ�е��迹�ĳ��ֱ����ؽ� ��SRR��
% INPUTS:--����:
%         imgn_lr : structure containing the LR images in EIDORS format, --���� EIDORS ��ʽ�е� LR ͼ��Ľṹ��
%                   with fields --���ֶεİٷֱȣ�
%                   - fwd_model.elems: array containing the elements --����Ԫ�ص�����
%                   - imgn_lr.fwd_model.nodes: array with the nodes --���ڵ������
%                   - imgn_lr.elem_data(:,t): electrodes * T array with
%                   voltage --�缫 * ����ѹ�� T ����
%                                             measurements for each time
%                                             instant --ÿ�μ�ʱ����
%         Nx, Ny  : width/height of the IHR/HR image in pixels --���� IHR/HR ͼ��Ŀ��/�߶�
% 
% OUTPUTS:--�����
%                   ��ͳһ�����а������ֱ���ͼ��ĵ�Ԫ����
%         srr_ims : cell array containing the super-resolved images, in an uniform grid 
%         MALHA   : structure containing data used for plotting the images
%         --�������ڻ���ͼ������ݵĽṹ
%         ImT     : structure containing the low-resolution images --�����ͷֱ���ͼ��Ľṹ
% ---------------------------------------------------------------------------


% add registration algorithm to path --��ע���㷨��ӵ�·��
addpath(genpath('hs'));


% ---------------------------------------------------------------------------
% convert to new format --ת��Ϊ�¸�ʽ

% number of frames --֡��
% T = size(imgn_lr.elem_data,2);
[~,T] = size(imgn_lr.elem_data);

% Load HR images --����HRͼ��  
for t=1:T
    imagens_reais(t).faces      = [];
    imagens_reais(t).vertices   = [];
    imagens_reais(t).cdata      = [];
    imagens_reais(t).faceColor  = [];
    imagens_reais(t).HR_uniform = [];
end

% Convert  LR images --ת��ΪLRͼ��
for t=1:T
    imagens_eit(t).faces     = imgn_lr.fwd_model.elems;
    imagens_eit(t).vertices  = imgn_lr.fwd_model.nodes;
    imagens_eit(t).cdata_LR  = imgn_lr.elem_data(:,t);
    imagens_eit(t).faceColor = 'flat';
end
%��Ԫ�ر���ȥ����ɫ���Ա����������
% Remove color from the elements face in order to plot only the mesh grid
for t=1:length(imagens_eit)
    imagens_eit(t).faceColor = 'none';
end

% Images are NOT registered beforehand: --δ����ע��ͼ��
UV = []; 
imagensRegistradas = false;





% ---------------------------------------------------------------------------
% Apply pre-processing --Ӧ��Ԥ����

%==========================================================================
%                               ѡ��                                      %
%============================== OPTIONS ===================================
%                                                                         %
%�� LR ͼ���������� [0��255] ��Χ��
% Normalize the LR images to the [0,255] range?
normalizarImagens = 0; % 1 --> yes  | 0 --> no


%==========================================================================
%                            ת��ͼ��                                            %
%========================= CONVERT THE IMAGES =============================
%                                                                         %
% originail data:
%��ʸ��������Ӧ��Ԫ���еĵ絼��ֵ
% im.cdata   : conductivity value in the elements corresponding to the vector indexes
% ÿ�а������ɸ���Ԫ�ص� 3 ����������
%im.faces   : each line contains 3 indexes of the vertices that compose a given element
% �������������ж��������
%im.vertices: coordinates of all existing vertices in the mesh
%�� LR ͼ��ת��Ϊ��ʽ��Ԫ�� #;x1��2��3;x1��2��3;��ֵ
% Converts the LR images to the format:   element #; x1,2,3; x1,2,3; value 
[imagens_reais,ImT] = converteCordenadas(imagens_reais,imagens_eit);

%==========================================================================
%                               ʹ������λ�ô�����������                                          %
%======== CREATES AUXILIARY MATRICES WITH PIXEL POSITIONS =================
% ʹ����ͳһ�����е����ض�Ӧ�� ��x��y�� λ�ô�����������                                                                        %
% Creates auxiliary matrices with the (x,y) positions corresponding to the
% pixels in the uniform grid

[ImAux] = criaMatrizesAux_comPosicao_dosPixels(ImT(1).coord, Nx, Ny);


%==========================================================================
%                            �����ͼ�� EM ���Ʒ� ��IHR��                                             %
%================= CRIA IMAGENS EM GRADE UNIFORME (IHR) ===================
%                             �� EIT ͼ�����²������Ʒ� ��IHR�� ����                                            %
% Returns the EIT images resampled to the uniform (IHR) grid
[ImT,imagens_reais,MascaraTemp] = reamostraTIE_uniforme(ImT,imagens_reais,normalizarImagens,Nx,Ny,ImAux);


% throw all images into a single cell array: --������ͼ����뵥����Ԫ�����У�
for t=1:length(ImT)
    ImT(t).imagem{1} = ImT(t).imagem_LR;
end




%
%==========================================================================
%                           ִ�г��ֱ����� LMS-SRR-EIT                                              %
%============= PERFORMS SUPER RESOLUTION WITH LMS-SRR-EIT =================
%                                                                         %

% LMS-SRR parameters --LMS-SRR ����
K  = 100;
mu = 0.01;
kernel = fspecial('gaussian',60,20);
utilizarPonderacao = 0; % do not weight the error according to the domain
%��Ҫ������Դ�����м�Ȩ

estimate_motion = 1;
alg_index = 1;
[erro,X_rec] = LMS_EIT_naoMatricial6(ImT,K,mu,Nx,Ny,kernel,ImAux,MascaraTemp,...
                                   utilizarPonderacao,imagens_reais,UV,estimate_motion,alg_index);

% attribute reconstructed image --�ؽ�ͼ������
srr_ims = X_rec;





% compute a structure used for ploting the FEM over the images
%����������ͼ���ϻ��� FEM �Ľṹ
[num_measurents,~] = size(ImT(1).coord.x);

% instantiate mesh --˲������
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





