function warpedim = warp_image( im1, Dx, Dy, flag_boundary )
% ��������ɫ��¼�Ƶ�ɫͼ��1��Ƶ����
[h, w] = size(im1) ;
[uc, vc] = meshgrid( 1:w, 1:h ) ;
uc1 = uc + Dx ;
vc1 = vc + Dy ;
warpedim = zeros( size(im1) ) ;
tmp = zeros(h, w) ;
interp_method = 'linear';      % 'nearest' -  ������ھӲ�ֵ

                              % 'linear'  -  ˫�߲�ֵ
                              % 'spline'  -  ��ֵ�ɽ�
                              % 'cubic'   -  ֻҪ�����Ƕ�Ԫ��ֵ,���ȼ����������"�ɽ�"��ͬ
switch flag_boundary
    case 0
        tmp = interp2(uc, vc, im1, uc1, vc1, interp_method, 0); % ��ĵ�
    case 1
        % ��������ͼ��
        im2 = [rot90(im1,2) flipud(im1) rot90(im1,2);...
               fliplr(im1)  im1         fliplr(im1);...
               rot90(im1,2) flipud(im1) rot90(im1,2)];
        [uc2, vc2] = meshgrid( -(w-1):2*w, -(h-1):2*h ); % ���������ָ��λ��
        tmp = interp2(uc2, vc2, im2, uc1, vc1, interp_method ); % ��ֵ
    case 2
        % ����ͼ���Բ�θ���
        im2 = [im1 im1 im1;...
               im1 im1 im1;...
               im1 im1 im1];
        [uc2, vc2] = meshgrid( -(w-1):2*w, -(h-1):2*h ); % ���������ָ��λ��
        tmp = interp2(uc2, vc2, im2, uc1, vc1, interp_method ); % ��ֵ
    case 3
        % ��������ͼ��
        im2 = [im1(1,1)*ones(size(im1))    meshgrid(im1(1,:))   im1(1,end)*ones(size(im1));...
               meshgrid(im1(:,1))'         im1                  meshgrid(im1(:,end))';...
               im1(end,1)*ones(size(im1))  meshgrid(im1(end,:)) im1(end,end)*ones(size(im1))];
        [uc2, vc2] = meshgrid( -(w-1):2*w, -(h-1):2*h );% ���������ָ��λ��       
        tmp = interp2(uc2, vc2, im2, uc1, vc1, interp_method );% ��ֵ
    otherwise
        disp('warp_image - Error: Invalid boundary flag selected! switching to zero padding')
end

warpedim(:, :) = tmp ;
warpedim(isnan(warpedim))=0;%��ĵ�
