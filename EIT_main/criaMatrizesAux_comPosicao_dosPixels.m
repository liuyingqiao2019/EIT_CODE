function [ImAux] = criaMatrizesAux_comPosicao_dosPixels(coord, Nx, Ny)
% ImAux = zeros(Ny,Nx);
ImAuxx = min(coord.x):((max(coord.x)-min(coord.x))/(Nx-1)):max(coord.x);
ImAuxy = min(coord.y):((max(coord.y)-min(coord.y))/(Nx-1)):max(coord.y);

% 始化坐标阵列并分配值
ImAux.Y = zeros(Ny,Nx);
ImAux.X = zeros(Ny,Nx);
for i=1:Nx
    ImAux.X(i,:) = ImAuxx;
end
for i=1:Ny
    ImAux.Y(:,i) = ImAuxy';
end
