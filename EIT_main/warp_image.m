function warpedim = warp_image( im1, Dx, Dy, flag_boundary )
% 调整个音色，录制单色图像（1个频道）
[h, w] = size(im1) ;
[uc, vc] = meshgrid( 1:w, 1:h ) ;
uc1 = uc + Dx ;
vc1 = vc + Dy ;
warpedim = zeros( size(im1) ) ;
tmp = zeros(h, w) ;
interp_method = 'linear';      % 'nearest' -  最近的邻居插值

                              % 'linear'  -  双线插值
                              % 'spline'  -  插值飞溅
                              % 'cubic'   -  只要数据是二元插值,均匀间隔，否则与"飞溅"相同
switch flag_boundary
    case 0
        tmp = interp2(uc, vc, im1, uc1, vc1, interp_method, 0); % 零衬垫
    case 1
        % 镜像输入图像
        im2 = [rot90(im1,2) flipud(im1) rot90(im1,2);...
               fliplr(im1)  im1         fliplr(im1);...
               rot90(im1,2) flipud(im1) rot90(im1,2)];
        [uc2, vc2] = meshgrid( -(w-1):2*w, -(h-1):2*h ); % 镜面区域的指数位置
        tmp = interp2(uc2, vc2, im2, uc1, vc1, interp_method ); % 插值
    case 2
        % 输入图像的圆形复制
        im2 = [im1 im1 im1;...
               im1 im1 im1;...
               im1 im1 im1];
        [uc2, vc2] = meshgrid( -(w-1):2*w, -(h-1):2*h ); % 镜面区域的指数位置
        tmp = interp2(uc2, vc2, im2, uc1, vc1, interp_method ); % 插值
    case 3
        % 复制输入图像
        im2 = [im1(1,1)*ones(size(im1))    meshgrid(im1(1,:))   im1(1,end)*ones(size(im1));...
               meshgrid(im1(:,1))'         im1                  meshgrid(im1(:,end))';...
               im1(end,1)*ones(size(im1))  meshgrid(im1(end,:)) im1(end,end)*ones(size(im1))];
        [uc2, vc2] = meshgrid( -(w-1):2*w, -(h-1):2*h );% 镜面区域的指数位置       
        tmp = interp2(uc2, vc2, im2, uc1, vc1, interp_method );% 插值
    otherwise
        disp('warp_image - Error: Invalid boundary flag selected! switching to zero padding')
end

warpedim(:, :) = tmp ;
warpedim(isnan(warpedim))=0;%零衬垫
