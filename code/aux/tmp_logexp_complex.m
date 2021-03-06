%%
% test for expM/logM of complex matrices

global logexp_fast_mode;
logexp_fast_mode = 1;

d = 2;
A = randn(d)+1i*randn(d);
X = A*A';

myerr = @(x,y)norm(x(:)-y(:))/norm(x(:));

myerr( logm(X) , logM(X) )

myerr( expm(logm(X)), expM(logm(X)) ) 


return;

[e1,e2,l1,l2] = tensor_eigendecomp(X);
Y = tensor_eigenrecomp(e1,e2,l1,l2);

u = squeeze(e1);
v = squeeze(e2);


X*u - l1*u
X*v - l2*v

Z = l1*u*u'+l2*v*v';

[V,S] = eig(X);