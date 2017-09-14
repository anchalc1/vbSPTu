function Piter(this,dat,iType)
tau=this.sample.shutterMean;
R  =this.sample.blurCoeff;

[wPi,wa,wB,n,c]=YZShmm.P0AD_sumStats(this.YZ,this.S,tau,R);
[nv,cv]=YZShmm.V_sumStats(this.YZ,this.S,dat);
switch lower(iType)
    case 'mle'
        this.P.wPi=wPi;
        this.P.wa =wa;
        this.P.wB =wB;
        this.P.n  =n;
        this.P.c  =c;
        % lump stats for all dimensions and states
        this.P.cv=sum(cv(:));
        this.P.nv=sum(nv(:));        
        % no KL terms in mle updates
        this.P.KL_pi=0;this.P.KL_a=0;this.P.KL_B=0;this.P.KL_lambda=0;this.P.KL_v=0;
    case 'map'
        this.P.wPi=this.P0.wPi+wPi;
        this.P.wa =this.P0.wa+wa;
        this.P.wB =this.P0.wB+wB;
        this.P.n  =this.P0.n+n;
        this.P.c  =this.P0.c+c;
        % lump stats for all dimensions and states        
        this.P.cv=this.P0.cv+sum(cv(:));
        this.P.nv=this.P0.nv+sum(nv(:));
        % no KL terms in map updates
        this.P.KL_pi=0;this.P.KL_a=0;this.P.KL_B=0;this.P.KL_lambda=0;this.P.KL_v=0;
    case 'vb'
        this.P.wPi=this.P0.wPi+wPi;
        this.P.wa =this.P0.wa+wa;
        this.P.wB =this.P0.wB+wB;
        this.P.n  =this.P0.n+n;
        this.P.c  =this.P0.c+c;
        % lump stats for all dimensions and states        
        this.P.cv=this.P0.cv+sum(cv(:));
        this.P.nv=this.P0.nv+sum(nv(:));        
        [this.P.KL_pi,this.P.KL_a,this.P.KL_B,this.P.KL_lambda]=YZShmm.P0AD_KLterms(this.P,this.P0);        
        
        this.P.KL_v= this.P0.nv.*log(this.P.cv./this.P0.cv)...
            -this.P.nv.*(1-this.P0.cv./this.P.cv)...
            -gammaln(this.P.nv)+gammaln(this.P0.nv)...
            +(this.P.nv-this.P0.nv).*psi(this.P.nv);
    case 'none'
        return
    otherwise
        error(['iType= ' iType ' not known. Use {mle,map,vb,none}.'] )
end
end