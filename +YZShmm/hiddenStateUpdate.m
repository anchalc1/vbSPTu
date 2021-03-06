function [S,sMaxP,sVit,funWS]=hiddenStateUpdate(dat,YZ,tau,R,iLambda,lnLambda,lnp0,lnQ,lnVs,iVs)
% [W,sMaxP,sVit,WS]=hiddenStateUpdate(dat,YZ,tau,R,iLambda,lnLambda,lnp0,lnQ,lnVs,iVs)
% one hidden state iteration for in adiffusive HMM, with possibly missing
% position data, and localization variances given either in the data or as
% model parameters lnVs, iVs (in which case the data is ignored).
%
% dat   : preprocessed data struct (spt.preprocess)
% YZ    : variational trajectory model struct
% tau   : W.shutterMean
% R     : W.blurCoeff
% iLambda : <1/lambda=W.P.n./W.P.c (VB), or 1./W.P.lambda (MLE)
% lnLambda: <ln(lambda)>=ln(W.P.c)-psi(W.P.n) (VB) or ln(lambda) (MLE)
% lnp0  : <ln(pi)>=psi(W.P.wPi)-psi(sum(W.P.wPi))   (VB) or ln(p0) (MLE)
% lnQ   : lnQ(i,i) = <ln(1-a(i))>                   (VB)
%         lnQ(i,j) = <ln(a(i))>  + <lnB(i,j)>, i~=j (VB)
%         <ln(1-a)> = psi(W.P.wa(:,2)) - psi(sum(W.P.wa,2)); (VB)
%         <ln(a)>   = psi(W.P.wa(:,1)) - psi(sum(W.P.wa,2)); (VB)
%         <ln(B)>   = psi(W.P.wB) - psi(sum(W.P.wB,2));      (VB)
%
%         or ln(A) (MLE).
% ------------------------------------------------------------------------
% for models where localization errors are fit parameters
% lnVs  : <ln v> =ln(cv)-psi(nv) (VB) or ln(v) (MLE)
% iVs   : <1./v> = nv./cv        (VB) or 1./v  (MLE)
% -------------------------------------------------------------------------
%
% sMAxP and sVit are only computed if asked for by output arguments.
% WS : struct containing the whole workspace at the end of the function
% call. Expensive, computed only when asked for.


% v1: modified from EMhmm version, checked correctness (not perfect, but
% good enough to blame on model differences...).
% v2: optimized computing lnH by getting rid of the trj loop

%% start of actual code
beta=tau*(1-tau)-R;
numStates=size(lnQ,1);
dim=size(dat.x,2);% data dimensionality
S=struct;
% extra contribution to lnH only when there are state-dependent
% localization uncertainties
addVterms=false;
if(exist('lnVs','var') && numel(lnVs)==numStates ...
        && exist('iVs','var') && numel(iVs)==numStates)
   addVterms=true;
end
%% assemble point-wise weights
T=YZ.i1(end);
lnH=-dim*ones(T,1)*lnLambda;
lnH(YZ.i0,:)=lnH(YZ.i0,:)+ones(length(YZ.i0),1)*lnp0;
lnH=lnH-sum(...
        [diff(YZ.muY).^2 ;zeros(1,dim)] ...
        +1/beta*(YZ.muZ-(1-tau)*YZ.muY-tau*YZ.muY([2:end end],:)).^2 ...
        +(1+(1-tau)^2/beta)*YZ.varY ...
        +(1+    tau^2/beta)*YZ.varY([2:end end],:) ...
        +1/beta*YZ.varZ...
        +2*R/beta*YZ.covYtYtp1...
        -2*(1-tau)/beta*YZ.covYtZt...
        -2*tau/beta*YZ.covYtp1Zt...
        ,2)/2*(iLambda);
if(addVterms)
    ot=isfinite(dat.x(:,1));
    dxz2=sum((dat.x-YZ.muZ).^2 + YZ.varZ,2);
    dxz2(~ot)=0;
    ot(YZ.i1)=0;
    lnH=lnH-0.5*(dim*ot*lnVs+dxz2*iVs);
end
lnH(YZ.i1,:)=0;
lnHmax=max(lnH,[],2);
lnH=lnH-lnHmax*ones(1,numStates);
H=exp(lnH);
H(YZ.i1,:)=0;
%% variational transition weights
lnQmax=max(lnQ(:));
Q=exp(lnQ-lnQmax);
%% forward-backward iteration
[lnZs,S.wA,S.pst]=HMM_multiForwardBackward_startend(Q,H,dat.i0,dat.i1);
S.lnZ=lnZs+sum(lnHmax)+lnQmax*sum(S.wA(:));
%% path estimates
if(nargout>=2) % compute sequence of most likely states
    [~,sMaxP]=max(S.pst,[],2);
    sMaxP(YZ.i1)=0;
end
if(nargout>=3) % compute Viterbi path, with a small offset to avoid infinities
    sVit=HMM_multiViterbi_log_startend(log(Q+1e-500),log(H+1e-500),dat.i0,dat.i1);
end
if(nargout>=4)
   fname=['foo_' int2str(ceil(1e5*rand)) '.mat'];
   save(fname);
   funWS=load(fname);
   delete(fname);
end
