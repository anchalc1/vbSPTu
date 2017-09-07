classdef dXt < YZShmm.YZS0
    % a hidden diffusive HMM with externally estimated point-wise
    % localization errors 
    properties
    end
    methods
        function this=dXt(varargin)            
            % dXt(N,opt,dat,p0_init,D_init,A_init)
            % same syntax as for the YZShmm.YZS0 constructor, except
            % that the data struct dat is expected to contain estimated
            % position variances.
            this=this@YZShmm.YZS0(varargin{:});

            % initialize trajectory model
            if(nargin>=3)
                dat=varargin{3};
                this.YZ=spt.naiveYZfromX(dat);
            end
        end
        P=getParameters(this,varargin);
    end
end
