% =========================================================================
% 描述：   一个使用训练好的网络进行超分辨率的应用demo（使用caffe的matlab接口）          
%    
% 参考文献：
%  Shi W, Caballero J, Huszar F, et al. Real-Time Single Image and Video
%  Super-Resolution Using an Efficient Sub-Pixel Convolutional Neural Network[C]
%  
% 王学文
% wangxuewen@yy.com
% =========================================================================
%                                                                         %
%% 设置
model = 'C:/Users/Administrator/Desktop/Super-Resolution-master/ESPCN/ESPCN_mat.prototxt';
weights = 'C:/Users/Administrator/Desktop/Super-Resolution-master/ESPCN/snapshot/espcn_iter_1000.caffemodel';
batch = 1;
up_scale = 3;
%% 导入数据
input = imread('C:/Users/Administrator/Desktop/Super-Resolution-master/Data/Test/Set14/lenna.bmp');
%if size(input,3)>1
    input2 = rgb2ycbcr(input);%RGB转Ycbcr
    input = input2(:,:, 1);
    im_l_cb = input2(:,:, 2);
    im_l_cr = input2(:,:, 3);
%end;
input = single(input)/255;
%input = imresize(input, 1/up_scale, 'bicubic');%降低图像分辨率,像素值取4x4邻域中的加权平均值
[height, width, channel] = size(input);
%% caffe使用cpu加速
caffe.reset_all(); 
caffe.set_mode_cpu();%清除所有solvers和生成的nets
%% 加载mat_caffe模型
net = caffe.Net(model,weights,'test');%创建网络并载入权重
net.blobs('data').reshape([height width channel batch]); 
net.reshape();%一次运行一张图片
net.blobs('data').set_data(input);%用input填充blob ‘data’
net.forward_prefilled();%使用input blobs(s)已经存在的数据进行前向计算
output = net.blobs('conv3').get_data();%从内部blobs中提取conv3层的特征
[output_height, output_width, output_channel] = size(output);%获取图片的尺寸、通道
scaled_height = up_scale * output_height;
scaled_width = up_scale * output_width;
im_h = zeros(scaled_height, scaled_width);
for m = 1 : up_scale
     for n = 1 : up_scale
         im_h(m:up_scale:scaled_height+m-up_scale,n:up_scale:scaled_width+n-up_scale) = output(:,:,(m-1)*up_scale+n);   
     end
end%卷积操作
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

