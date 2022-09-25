% =========================================================================
% ������   ����ѵ�����������߷ֱ���ͼƬ�²���ָ�����ʵõ��ͷֱ���ͼ���ٽ��߷ֱ�
%          ��ͼ�����ųɶ���Сͼʹ֮���ص��ڵͷֱ���ͼ��λ��һһ��Ӧ���ڸߵͷֱ���
%          ͼ������ȡͼ�����Ϊ������ϴ�ƴ��Һ�д��hdf5�ļ���           
% =========================================================================
clear;close all;
%% ����
folder = '../Data/Train';
savepath = 'train_espcn.h5';
size_input = 25;
size_label = 17;
scale = 3;
stride = 14;
chunksz = 128;

%% ����
data = zeros(size_input, size_input, 1, 1);
label = zeros(size_label, size_label, scale*scale, 1);
padding = abs(size_input - size_label)/2;
count = 0;

%% ��ʼ����
filepaths = dir(fullfile(folder,'*.bmp'));
for i = 1 : length(filepaths)  
    image = imread(fullfile(folder,filepaths(i).name));
    image = rgb2ycbcr(image);
    image = im2double(image(:, :, 1));
    image = modcrop(image, scale);
    [hei,wid] = size(image);
    im_label = zeros(hei/scale,wid/scale,scale*scale);
    im_input = imresize(image,1/scale,'bicubic');
    
    for m = 1 : scale
        for n = 1 : scale
            im_label(:,:,(m-1)*scale+n) = image(m:scale:hei+m-scale,n:scale:wid+n-scale);
        end
    end
    
    for x = 1 : stride : hei / scale-size_input+1
       for y = 1 :stride : wid /scale-size_input+1
            
            subim_input = im_input(x : x+size_input-1, y : y+size_input-1);
            subim_label = im_label(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);

            count=count+1;
            data(:, :, 1, count) = subim_input;
            label(:, :, :, count) = subim_label;
       end
   end
end
order = randperm(count);
data = data(:, :, 1, order);
label = label(:, :, :, order); 

%% д��HDF5��
created_flag = false;
totalct = 0;

for batchno = 1:floor(count/chunksz)
    last_read=(batchno-1)*chunksz;
    batchdata = data(:,:,1,last_read+1:last_read+chunksz); 
    batchlabs = label(:,:,:,last_read+1:last_read+chunksz);

    startloc = struct('dat',[1,1,1,totalct+1], 'lab', [1,1,1,totalct+1]);
    curr_dat_sz = store2hdf5(savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz); 
    created_flag = true;
    totalct = curr_dat_sz(end);
end
h5disp(savepath);
