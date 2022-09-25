function [srr_ims,MALHA,ImT,scs_name]=EIT_ESPCN(imgn_lr,Nx,Ny)
%% ����
model = 'ESPCN/ESPCN_mat.prototxt';
weights = 'ESPCN/snapshot/espcn_iter_1000.caffemodel';
batch = 1;
up_scale = 3;

%% ��������
input = imread('../Data/original.png');
% if size(input,3)>1
    input2 = rgb2ycbcr(input);% RGBתYcbcr
    input = input2(:,:, 1);
    im_l_cb = input2(:,:, 2);
    im_l_cr = input2(:,:, 3);
% end;
input = single(input)/255;

% ����ͼ��ֱ���,����ֵȡ4-�����еļ�Ȩƽ��ֵ
input = imresize(input, 1/up_scale, 'bicubic');
[height, width, channel] = size(input);

%% caffeʹ��cpu����
caffe.reset_all(); 
caffe.set_mode_cpu();% �������solvers�����ɵ�nets

%% ����mat_caffeģ��
net = caffe.Net(model,weights,'test');% �������粢����Ȩ��
net.blobs('data').reshape([height width channel batch]); 
net.reshape();% һ������һ��ͼƬ
net.blobs('data').set_data(input);% ��input���blob ��data��
net.forward_prefilled();% ʹ��input blobs(s)�Ѿ����ڵ����ݽ���ǰ�����
output = net.blobs('conv3').get_data();% ���ڲ�blobs����ȡconv3�������
[output_height, output_width, output_channel] = size(output);% ��ȡͼƬ�ĳߴ硢ͨ��
scaled_height = up_scale * output_height;
scaled_width = up_scale * output_width;
im_h = zeros(scaled_height, scaled_width);

% �ͷֱ���ͼ���Ͻ��о������
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

% ����HRͼ��  
for t=1:T
    imagens_reais(t).faces      = [];
    imagens_reais(t).vertices   = [];
    imagens_reais(t).cdata      = [];
    imagens_reais(t).faceColor  = [];
    imagens_reais(t).HR_uniform = [];
end

% ת��ΪLRͼ��
for t=1:T
    imagens_eit(t).faces     = imgn_lr.fwd_model.elems;
    imagens_eit(t).vertices  = imgn_lr.fwd_model.nodes;
    imagens_eit(t).cdata_LR  = imgn_lr.elem_data(:,t);
    imagens_eit(t).faceColor = 'flat';
end

% ��Ԫ�ر���ȥ����ɫ���Ա����������
for t=1:length(imagens_eit)
    imagens_eit(t).faceColor = 'none';
end

% δ����ע��ͼ��
UV = []; 
imagensRegistradas = false;

                                                                        
% �� LR ͼ���������� [0��255] ��Χ��
normalizarImagens = 0; % 1 --> yes  | 0 --> no

%% ת��ͼ��                                                                                                                   
% im.cdata   : %��ʸ��������Ӧ��Ԫ���еĵ絼��ֵ
% im.faces   :  % ÿ�а������ɸ���Ԫ�ص� 3 ����������
% im.vertices: % �������������ж��������
[imagens_reais,ImT] = converteCordenadas(imagens_reais,imagens_eit);% �� LR ͼ��ת��Ϊ��ʽ��Ԫ�� #;x1��2��3;x1��2��3;��ֵ

%% ʹ������λ�ô�����������                                          
% ʹ����ͳһ�����е����ض�Ӧ�� ��x��y�� λ�ô�����������                                                                        
[ImAux] = criaMatrizesAux_comPosicao_dosPixels(ImT(1).coord, Nx, Ny);

% �� EIT ͼ�����²������Ʒ� ��IHR�� ����                                            
[ImT,imagens_reais,MascaraTemp] = reamostraTIE_uniforme(ImT,imagens_reais,normalizarImagens,Nx,Ny,ImAux);

% ������ͼ����뵥����Ԫ�����У�
for t=1:length(ImT)
    ImT(t).imagem{1} = ImT(t).imagem_LR;
end

%% ִ�г��ֱ����� LMS-SRR-EIT                                              
% LMS-SRR ����
K  = 100;
mu = 0.01;
kernel = fspecial('gaussian',60,20);
utilizarPonderacao = 0; % ��Ҫ������Դ�����м�Ȩ
estimate_motion = 1;
alg_index = 1;
[erro,X_rec] = LMS_EIT_naoMatricial6(ImT,K,mu,Nx,Ny,kernel,ImAux,MascaraTemp,...
                                   utilizarPonderacao,imagens_reais,UV,estimate_motion,alg_index);
srr_ims = X_rec;% �ؽ�ͼ������
[num_measurents,~] = size(ImT(1).coord.x);% ����������ͼ���ϻ��� FEM �Ľṹ

% ˲������
clear MALHA
MALHA.coord.x = ImT(1).coord.x;
MALHA.coord.y = ImT(1).coord.y;
MALHA.cdata   = zeros(num_measurents,1);
MALHA.coord.x = MALHA.coord.x + max(MALHA.coord.x(:)) + (2/Nx); %+ max(max(MALHA.coord.x))*ones(length(MALHA.coord.x),3) + (1/Nx);
MALHA.coord.y = MALHA.coord.y + max(MALHA.coord.y(:)) + (2/Ny);
MALHA.coord.x = MALHA.coord.x*(Nx-(1))/max(MALHA.coord.x(:));
MALHA.coord.y = MALHA.coord.y*(Ny-(1))/max(MALHA.coord.y(:));

