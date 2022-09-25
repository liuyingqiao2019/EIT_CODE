% =========================================================================
% ������   һ��ʹ��ѵ���õ�������г��ֱ��ʵ�Ӧ��demo��ʹ��caffe��matlab�ӿڣ�          
%    
% �ο����ף�
%  Shi W, Caballero J, Huszar F, et al. Real-Time Single Image and Video
%  Super-Resolution Using an Efficient Sub-Pixel Convolutional Neural Network[C]
%  
% ��ѧ��
% wangxuewen@yy.com
% =========================================================================
%                                                                         %
%% ����
model = 'C:/Users/Administrator/Desktop/Super-Resolution-master/ESPCN/ESPCN_mat.prototxt';
weights = 'C:/Users/Administrator/Desktop/Super-Resolution-master/ESPCN/snapshot/espcn_iter_1000.caffemodel';
batch = 1;
up_scale = 3;
%% ��������
input = imread('C:/Users/Administrator/Desktop/Super-Resolution-master/Data/Test/Set14/lenna.bmp');
%if size(input,3)>1
    input2 = rgb2ycbcr(input);%RGBתYcbcr
    input = input2(:,:, 1);
    im_l_cb = input2(:,:, 2);
    im_l_cr = input2(:,:, 3);
%end;
input = single(input)/255;
%input = imresize(input, 1/up_scale, 'bicubic');%����ͼ��ֱ���,����ֵȡ4x4�����еļ�Ȩƽ��ֵ
[height, width, channel] = size(input);
%% caffeʹ��cpu����
caffe.reset_all(); 
caffe.set_mode_cpu();%�������solvers�����ɵ�nets
%% ����mat_caffeģ��
net = caffe.Net(model,weights,'test');%�������粢����Ȩ��
net.blobs('data').reshape([height width channel batch]); 
net.reshape();%һ������һ��ͼƬ
net.blobs('data').set_data(input);%��input���blob ��data��
net.forward_prefilled();%ʹ��input blobs(s)�Ѿ����ڵ����ݽ���ǰ�����
output = net.blobs('conv3').get_data();%���ڲ�blobs����ȡconv3�������
[output_height, output_width, output_channel] = size(output);%��ȡͼƬ�ĳߴ硢ͨ��
scaled_height = up_scale * output_height;
scaled_width = up_scale * output_width;
im_h = zeros(scaled_height, scaled_width);
for m = 1 : up_scale
     for n = 1 : up_scale
         im_h(m:up_scale:scaled_height+m-up_scale,n:up_scale:scaled_width+n-up_scale) = output(:,:,(m-1)*up_scale+n);   
     end
end%�������
im_h = im_h * 255;
[nrow, ncol] = size(im_h);
im_h_cb = imresize(im_l_cb, [nrow, ncol], 'bicubic');
im_h_cr = imresize(im_l_cr, [nrow, ncol], 'bicubic');

im_h_ycbcr = zeros([nrow, ncol, 3]);
im_h_ycbcr(:, :, 1) = im_h;
im_h_ycbcr(:, :, 2) = im_h_cb;
im_h_ycbcr(:, :, 3) = im_h_cr;
%[height, width, channel] = size(im_h);
im_h = ycbcr2rgb(uint8(im_h_ycbcr));
%im_h = uint8(im_h * 255);

imwrite(im_h,'C:/Users/Administrator/Desktop/Super-Resolution-master/ESPCN/result/espcn_caffe.bmp');

