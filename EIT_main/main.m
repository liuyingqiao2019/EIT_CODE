% 基于ESPCN神经网络的超分辨率重建算法
% 用于生成断层扫描 （EIT） 图像

clear all
close all
warning off;
clc
t1=clock;
scs_name = 'test';
load('EIT_real_lung_images.mat')%加载Montreal数据（可与EIDORS）和三个重建，NOSER，总变异和临时解算器

 imgn_lr = real_lung_img_LR_NOSER;
 % imgn_lr = real_lung_img_LR_TS;
 % imgn_lr = real_lung_img_LR_TV;



% HR图像的尺寸
Nx = 200;
Ny = 200;

[srr_ims,MALHA,ImT,scs_name] = EIT_ESPCN(imgn_lr,Nx,Ny);% 执行超分辨率
%[srr_ims,MALHA,ImT] = EIT_SRR(imgn_lr,Nx,Ny);

imgs_to_print = [10 20];% 输出图像的尺寸
mkdir('figures_1/')% 新建一个目录

for im_idx = imgs_to_print
    %clear imagem_lr_show 
    
    % 输出生成的LR图像
    imagem_lr_show.coord.x  = ImT(im_idx).coord.x;
    imagem_lr_show.coord.y  = ImT(im_idx).coord.y;
    imagem_lr_show.cdata    = ImT(im_idx).coord.value_LR;
    figure, set(gca,'color','none'), set(gca,'visible','off')
    
    % 绘制多个填充多边形区域
    patch(imagem_lr_show.coord.x',imagem_lr_show.coord.y',...
         [imagem_lr_show.cdata  imagem_lr_show.cdata  imagem_lr_show.cdata]')
    axis equal  
    
  % caxis([minval_tmp maxval_tmp])%设置颜色图范围
    print(['figures_1/' scs_name '_LR_t',num2str(im_idx)], '-dpdf')
    print(['figures_1/' scs_name '_LR_t',num2str(im_idx)], '-dpng')
    % 输出重建图
    figure, 
    % set(gca,'color','none'), 
    % set(gca,'visible','off')
    
    imagesc(flipud(srr_ims{im_idx}))  % 转换颜色,imagesc把m*n*3的矩阵中的数值当做RGB值来显示的，flipud将数组上下翻转，im_idx图片大小
    set(gca,'color','none'), set(gca,'visible','off')
    h = patch(MALHA.coord.x',MALHA.coord.y',...
         [MALHA.cdata  MALHA.cdata  MALHA.cdata]','FaceColor','none');  
    rotate(h,[0,0,1],180)% 旋转图像
  % axis equal % square
  % caxis([minval_tmp maxval_tmp])
    print(['figures_1/' scs_name '_SRR_t',num2str(im_idx)], '-dpdf')    
    print(['figures_1/' scs_name '_SRR_t',num2str(im_idx)], '-dpng')
    t2=clock;
    t=etime(t2,t1);
    fprintf('运行时间为%f\n',t)
	img1= imread('../Data/original.png');
	img2= imread('figures_1/test_SRR_t20.png');
    img3= imread('figures_1/espcn_caffe_SRR_t20.png');
	ssim_value_1=SSIM1(img1,img2)
    ssim_value_2=SSIM1(img1,img3)
    
end