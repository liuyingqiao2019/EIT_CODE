% ����ESPCN������ĳ��ֱ����ؽ��㷨
% �������ɶϲ�ɨ�� ��EIT�� ͼ��

clear all
close all
warning off;
clc
t1=clock;
scs_name = 'test';
load('EIT_real_lung_images.mat')%����Montreal���ݣ�����EIDORS���������ؽ���NOSER���ܱ������ʱ������

 imgn_lr = real_lung_img_LR_NOSER;
 % imgn_lr = real_lung_img_LR_TS;
 % imgn_lr = real_lung_img_LR_TV;



% HRͼ��ĳߴ�
Nx = 200;
Ny = 200;

[srr_ims,MALHA,ImT,scs_name] = EIT_ESPCN(imgn_lr,Nx,Ny);% ִ�г��ֱ���
%[srr_ims,MALHA,ImT] = EIT_SRR(imgn_lr,Nx,Ny);

imgs_to_print = [10 20];% ���ͼ��ĳߴ�
mkdir('figures_1/')% �½�һ��Ŀ¼

for im_idx = imgs_to_print
    %clear imagem_lr_show 
    
    % ������ɵ�LRͼ��
    imagem_lr_show.coord.x  = ImT(im_idx).coord.x;
    imagem_lr_show.coord.y  = ImT(im_idx).coord.y;
    imagem_lr_show.cdata    = ImT(im_idx).coord.value_LR;
    figure, set(gca,'color','none'), set(gca,'visible','off')
    
    % ���ƶ�������������
    patch(imagem_lr_show.coord.x',imagem_lr_show.coord.y',...
         [imagem_lr_show.cdata  imagem_lr_show.cdata  imagem_lr_show.cdata]')
    axis equal  
    
  % caxis([minval_tmp maxval_tmp])%������ɫͼ��Χ
    print(['figures_1/' scs_name '_LR_t',num2str(im_idx)], '-dpdf')
    print(['figures_1/' scs_name '_LR_t',num2str(im_idx)], '-dpng')
    % ����ؽ�ͼ
    figure, 
    % set(gca,'color','none'), 
    % set(gca,'visible','off')
    
    imagesc(flipud(srr_ims{im_idx}))  % ת����ɫ,imagesc��m*n*3�ľ����е���ֵ����RGBֵ����ʾ�ģ�flipud���������·�ת��im_idxͼƬ��С
    set(gca,'color','none'), set(gca,'visible','off')
    h = patch(MALHA.coord.x',MALHA.coord.y',...
         [MALHA.cdata  MALHA.cdata  MALHA.cdata]','FaceColor','none');  
    rotate(h,[0,0,1],180)% ��תͼ��
  % axis equal % square
  % caxis([minval_tmp maxval_tmp])
    print(['figures_1/' scs_name '_SRR_t',num2str(im_idx)], '-dpdf')    
    print(['figures_1/' scs_name '_SRR_t',num2str(im_idx)], '-dpng')
    t2=clock;
    t=etime(t2,t1);
    fprintf('����ʱ��Ϊ%f\n',t)
	img1= imread('../Data/original.png');
	img2= imread('figures_1/test_SRR_t20.png');
    img3= imread('figures_1/espcn_caffe_SRR_t20.png');
	ssim_value_1=SSIM1(img1,img2)
    ssim_value_2=SSIM1(img1,img3)
    
end