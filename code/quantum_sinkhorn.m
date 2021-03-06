function [gamma,u,v,err] = quantum_sinkhorn(mu,nu,c,epsilon,rho, options)

% quantum_sinkhorn - Quantum Sinkhorn iterations
%
%   [gamma,u,v,err] = quantum_sinkhorn(mu,nu,c,epsilon,rho, options);
%
%   Solve for 
%       min_gamma KL(gamma|xi) + lambda*KL(gamma*1|mu) + lambda*KL(gamma^T*1|mu)
%   where xi=expm(-c/epsilon) and lambda=rho/epsilon.
%
%   options.niter is the number of Sinkhorn iterates.
%   options.display_func(gamma,mu,nu) is a callback for display.
%
%   options.tau controls averaging step size.
%       tau = 1/(1+lambda) is the detault and corresponds to usual Sinkhorn steps.
%       1/(1+lambda) < tau < 2/(1+lambda) corresponds to extrapolation, and
%           can sometimes accelerate a lot.
%
%   Copyright (c) 2016 Gabriel Peyre

N = [size(mu,3) size(nu,3)];
d = size(mu,1); % dimension

options.null = 0;
niter = getoptions(options, 'niter', 100);
% display marginals
disp_func = getoptions(options, 'disp_func', @mydisplay);
disp_rate = getoptions(options, 'disp_rate', max(2,ceil(niter/100)) );
tol = getoptions(options, 'tol', 1e-15 );
% relaxation parameter
lambda = rho/epsilon;
tau = getoptions(options, 'tau', 1/(lambda+1));

% init
v = nu*0;
u = mu*0;
% log of densities
Lmu = logM(mu);
Lnu = logM(nu);

K = @(u,v) -c/epsilon ...
    -lambda*repmat( reshape(v,[d d 1 N(2)]),[1 1 N(1) 1]) ...
    -lambda*repmat( u,[1 1 1 N(2)]);

perm = @(x)permute(x, [1 2 4 3]); 
relax = @(x,y,tau)x*(1-tau)+y*tau;
notnan = @(x)x(not(isnan(x(:))));
mynorm = @(x)norm(notnan(x));

err = [];
for it=1:niter
    progressbar(it,niter);
    %%%%% update u %%%%
	u1 = relax(u, lse_uv(c,u,v,epsilon,rho,0) - Lmu, tau);
    err(it,1) = mynorm(u-u1);
    u = u1;
    if not(isempty(disp_func)) && mod(it,disp_rate)==1
        gamma = recomp_coupling(c,u,v,epsilon,rho);
        disp_func(gamma,mu,nu);
    end
    %%%%% update v %%%%
    v1 = relax(v, lse_uv(c,u,v,epsilon,rho,1) - Lnu, tau);      
    err(it,2) = mynorm(v-v1);
    v = v1;
    if not(isempty(disp_func)) && mod(it,disp_rate)==ceil(disp_rate/2)
        gamma = recomp_coupling(c,u,v,epsilon,rho);
        disp_func(gamma,mu,nu);
    end
    if max(err(it,:))<tol
        progressbar(niter,niter);
        break;
    end
end
gamma = recomp_coupling(c,u,v,epsilon,rho);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mydisplay(gamma,mu,nu)

% compares trace
A0 = trM(mu,1);
B0 = trM(nu,1);
A = trM(sum(gamma,4),1);
B = trM(sum(gamma,3),1);
clf;
subplot(2,1,1);
plot([A A0]); legend('gamma1', 'mu');
subplot(2,1,2);
plot([B B0]); legend('gamma2', 'nu');
drawnow;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma = recomp_coupling(c,u,v,epsilon,rho)

lambda = rho/epsilon;
d = size(u,1);
if issparse(c)
    % sparse coupling format
    [i,j,cij] = find(c);
    gamma.T = expM( -tensor_id(cij,d)/epsilon-lambda*u(:,:,i)-lambda*v(:,:,j) );
    gamma.i = i; gamma.j = j; 
    return;
end
d = size(u,1); % dimension
N(1) = size(c,3); N(2) = size(c,4);
resh = @(x)reshape(x, [d d N(1) N(2)]);
flat = @(x)reshape(x, [d d N(1)*N(2)]);
a = -c/epsilon -lambda*repmat( reshape(v,[d d 1 N(2)]),[1 1 N(1) 1]) ...
    - lambda*repmat( u,[1 1 1 N(2)]);
gamma =  resh( expM(flat(a))  );

end