function [X,D,Vor,v] = farthesh_point(mu,P, options)

% farthesh_point - perform farthest point sampling according to some anisotropic metric
%
%   [X,D,Vor,v] = farthesh_point(mu,P, options);
%
%   mu should be of size (n,n,2,2)
%   P is the number of sampling point
%   X(:,i) is the ith sampled point, in [1,n]^2
%   D is the geodesic distance
%   Vor are Vornoi cell indexes of the points in [1,P]
%   (v(:,1),v(:,2)) is an edge of the geodesic Delaunay triangulation.
%   Set options.disp_rate to contol display rate.
%
% Warning: you need to compile the mex file fm2dAniso.cpp before.
%
%   Copyright (c) 2016 Gabriel Peyre

options.null = 0;
disp_rate = getoptions(options, 'disp_rate', 10);

n = size(mu,3);

%%
% Farthest point sampling.

X = getoptions(options, 'X0', [[1;1], [n;1], [1;n], [n;n]]); % first point
for k=size(X,2)+1:P
    progressbar(k,P);
    [D,Vor] = anisotropic_fm(mu,X);    
    [~,i] = max(D(:)); [i1,i2] = ind2sub([n n], i(1));
    X(:,end+1) = [i1;i2];
    if mod(k,disp_rate)==1
        clf; hold on;
        imagesc(1:n,1:n,D'); colormap parula(256);
        plot(X(1,:), X(2,:), 'r.', 'MarkerSize', 15);
        axis ij; axis image; axis off; drawnow;
    end
end
[D,Vor] = anisotropic_fm(mu,X);

% get NN connectivity for the Delaunay triangulation
flat = @(x)x(:);
u = [flat(Vor(1:end-1,:)) flat(Vor(2:end,:)); flat(Vor(:,1:end-1)) flat(Vor(:,2:end))];
u = u(u(:,1)~=u(:,2),:);
u = sort(u,2);
v = unique(u, 'rows');

% add missing edges to obtain valid triangulation
DT = delaunayTriangulation(X', double(v));
v = [DT.ConnectivityList(:,1:2); ...
    DT.ConnectivityList(:,2:3); ...
    DT.ConnectivityList(:,[1 3])];
X = DT.Points';
v = sort(v,2);
v = unique(v, 'rows');

% fix points very clost to the boundary
btol = getoptions(options, 'btol', n/30);
X(X<btol) = 1; X(X>n-btol) = n;

end
