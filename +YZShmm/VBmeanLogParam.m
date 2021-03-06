function [lnp0,lnQ,iLambda,lnLambda]=VBmeanLogParam(wPi,wa,wB,n,c)
% [lnp0,lnQ,iLambda,lnLambda]=VBmeanLogParam(wPi,wa,wB,n,c)
% varational parameter log-averages needed for VB updates of hidden states
%
% iLambda : <1/lambda=n./c
% lnLambda: <ln(lambda)>=log(c)-psi(n)
% lnp0  : <ln(pi)>=psi(wPi)-psi(sum(wPi))
% lnQ   : lnQ(i,i) = <ln(1-a(i))> 
%         lnQ(i,j) = <ln(a(i))>  + <lnB(i,j)>, i~=j
%         <ln(1-a)> = psi(wa(:,2)) - psi(sum(wa,2)); (VB)
%         <ln(a)>   = psi(wa(:,1)) - psi(sum(wa,2)); (VB)
%         <ln(B)>   = psi(wB) - psi(sum(wB,2));      (VB)
% note that lambda and localization variances have the same type of
% variational distributions (inverse gamma), and hence calling with
% (n,c)->(nv,cv) will give results that can be interpreted using lambda->v.

% initial state probability
lnp0=psi(wPi)-psi(sum(wPi)); % <ln(pi)>

% state change probabilities, <ln(a)>, <ln(1-a)>
wa0=sum(wa,2);
lna  =psi(wa(:,1))-psi(wa0);
ln1ma=psi(wa(:,2))-psi(wa0);

% conditional jump probabilities, <lnB>, with zeros on the diagonal
N=size(wB,1);
I=eye(N); % N*N identity matrix
wB0=sum(wB,2)*ones(1,N);
lnBd0  = psi(wB+I)-psi(wB0);
lnBd0=lnBd0-diag(diag(lnBd0));
if(N>1)
    lnQ=diag(ln1ma)+(lna*ones(1,N)-diag(lna))+lnBd0; % <ln A> or ln A
else
    lnQ=0;
end

% step length variance
iLambda =n./c; % <1/lambda>
lnLambda=log(c)-psi(n); % < ln(lambda)>
