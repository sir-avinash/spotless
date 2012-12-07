classdef spotsqlprg
    properties 
        % Developer's Notes about Internal Representation:
        % 
        % The program consists of a collection of variable dimensions:
        % 
        % name -- Character prefix for variables from the program.
        %
        %
        % posNum  -- 1-by-1 Positive integer (number of non-negative variables).
        % freeNum -- 1-by-1 Positive integer (number of non-negative variables).
        % psdDim -- Npsd-by-1 array of positive integers.  Each represents
        %                     psdDim(i)-by-psdDim(i) dim. variable.
        % lorDim -- Nlor-by-1 array of positive integers.  Size of
        %                     Lorentz cones (n indicates x(1)^2 >=
        %                     sum_i=2^n x(i)^2 )
        % rlorDim -- Nrlor-by-1 array of positive integers, similar
        %                     for rotated Lorentz cones.
        %
        % Variables are named @psdi, @lori, @posi @rlri, where @ is
        % replaced by 'name' and 'i' is a running counter.
        %
        %
        %
        name = '@';
        
        posNum  = 0;
        freeNum = 0;
        psdDim  = [];
        lorDim  = [];
        rlorDim = [];
        
        equations = [];
    end

    methods (Static)
        function n = psdDimToNo(d)
            n=(d+1).*d/2;
        end
    end
    
    methods ( Access = private )
        function nm = freeName(pr)
            nm = [pr.name 'fr'];
        end
        function nm = posName(pr)
            nm = [pr.name 'pos'];
        end
        function nm = psdName(pr)
            nm = [pr.name 'psd'];
        end
        function nm = lorName(pr)
            nm = [pr.name 'lor'];
        end
        function nm = rlorName(pr)
            nm = [pr.name 'rlr'];
        end
        function nm = dualName(pr)
            nm = [pr.name 'dl'];
        end
        
        
        function f = freeVariables(pr)
            f = msspoly(pr.freeName,pr.numFree);
        end
        function p = posVariables(pr)
            p = msspoly(pr.posName,pr.numPos);
        end
        function l = lorVariables(pr)
            l = msspoly(pr.lorName,pr.numLor);
        end
        function r = rlorVariables(pr)
            r = msspoly(pr.rlorName,pr.numRLor);
        end
        function p = psdVariables(pr)
            p = msspoly(pr.psdName,pr.numPSD);
        end
        

        
        function flag = realLinearInDec(pr,exp)
            [x,pow,Coeff] = decomp(exp);
            [~,xid] = isfree(x);
            [~,vid] = isfree(pr.variables);
            flag = ~(any(mss_match(vid,xid) == 0) | ...
                     any(pow(:) > 1) | ...
                     any(imag(Coeff(:)) ~= 0));
        end
        
        function flag = legalEq(pr,eq)
            if ~(size(eq,2) == 1 && ...
                 size(eq,1) > 0  && ...
                 isa(eq,'msspoly'))
                flag = 0;
            else
                flag = realLinearInDec(pr,eq);
            end
        end
    end
    methods
        
        function v = variables(pr)
        % v = variables(pr)
        % Column of decision variables in the program pr.
            v = [ pr.freeVariables
                  pr.posVariables
                  pr.lorVariables
                  pr.rlorVariables
                  pr.psdVariables];
        end
        
        
        function pr=spotsqlprg(name)
            if nargin > 0
                if ~ischar(name) || length(name) > 1
                    error('Program name must be a scalar character.');
                else
                    msspoly(name);
                end
                pr.name = name;
            end
        end
        

        function n = numPos(pr)
            n = pr.posNum;
        end
        function n = numFree(pr)
            n = pr.freeNum;
        end
        function n = numPSD(pr)
            n = sum(spotsqlprg.psdDimToNo(pr.psdDim));
        end
        function n = numLor(pr)
            n = sum(pr.lorDim);
        end
        function n = numRLor(pr)
            n = sum(pr.rlorDim);
        end
        
        function m = numEq(pr)
            m = length(pr.equations);
        end
        
        function [pr,Q] = newPSD(pr,dim)
            if ~spot_hasSize(dim,[1 1]) || ~spot_isIntGE(dim,1)
                error('Dimension must be scalar positive integer.');
            end
            n = spotsqlprg.psdDimToNo(dim);
            
            Q = mss_v2s(msspoly(pr.psdName,[n pr.numPSD]));
            
            pr.psdDim = [pr.psdDim dim];
        end
        
        function [pr,Qs] = newBlkPSD(pr,dim)
            if ~spot_hasSize(dim,[1 2]) || ~spot_isIntGE(dim,1)
                error('Dimension must be 1x2 positive integer.');
            end
            
            n = spotsqlprg.psdDimToNo(dim(1));
            
            Qs = reshape(msspoly(pr.psdName,[n*dim(2) pr.numPSD]),n,dim(2));
            pr.psdDim = [pr.psdDim dim(1)*ones(1,dim(2))];
        end
        
        function [pr,p] = newPos(pr,dim)
            if ~spot_hasSize(dim,[1 1]) || ~spot_isIntGE(dim,1)
                error('Dimension must be scalar positive integer.');
            end
            
            p = msspoly(pr.posName,[dim pr.numPos]);
            
            pr.posNum = pr.posNum+dim;
        end
        
        function [pr,f] = newFree(pr,dim)
            if ~spot_hasSize(dim,[1 1]) || ~spot_isIntGE(dim,1)
                error('Dimension must be scalar positive integer.');
            end
            
            f = msspoly(pr.freeName,[dim pr.numFree]);
            
            pr.freeNum = pr.freeNum+dim;
        end
        
        function [pr,l] = newLor(pr,dim)
            if spot_hasSize(dim,[1 1]), dim = [dim 1]; end
            if ~spot_hasSize(dim,[1 2]) || ~spot_isIntGE(dim,1)
                error('Dimension must be 1x2 positive integer.');
            end
            
            l = reshape(msspoly(pr.lorName,[prod(dim) pr.numLor]),dim(1),dim(2));
            
            pr.lorDim = [pr.lorDim dim(1)*ones(1,dim(2))];
        end
        
        function [pr,r] = newRLor(pr,dim)
            if spot_hasSize(dim,[1 1]), dim = [dim 1]; end
            if ~spot_hasSize(dim,[1 2]) || ~spot_isIntGE(dim,1)
                error('Dimension must be 1x2 positive integer.');
            end
            
            r = reshape(msspoly(pr.rlorName,[prod(dim) pr.numRLor]),dim(1),dim(2));
            
            pr.rlorDim = [pr.rlorDim dim(1)*ones(1,dim(2))];
        end
        
        function [pr,y] = withEqs(pr,eq)
            if ~pr.legalEq(eq)
                error(['Equations must be a column msspoly linear in ' ...
                       'decision parameters.']);
            end
            
            y = msspoly(pr.dualName,[length(eq) pr.numEq]);
            pr.equations = [pr.equations ; eq];
        end
         
        %-- 
        function [pr,s,y] = withPos(pr,exp)
            if ~isa(exp,'msspoly')
                error('Argument must be a column of msspoly expressions.');
            end
            exp = exp(:);
            
            [pr,s] = pr.newPos(length(exp));
            [pr,y] = pr.withEqs(exp - s);
        end
        
        function [pr,Q,y] = withPSD(pr,exp)
            if ~isa(exp,'msspoly') || size(exp,1) ~= size(exp,2)
                error('Argument must be a square msspoly.');
            end
            
            if size(exp,1) == 1
                [pr,l,y] = pr.withPos(pr,exp);
            else
                [pr,Q] = pr.newPSD(size(exp,1));
                [pr,y] = pr.withEqs(mss_s2v(exp-Q));
            end
        end
        
        function [pr,s,y] = withBlkPSD(pr,exp)
            if ~isa(exp,'msspoly')
                error('Argument must be an msspoly.');
            end
            if ~spotsqlprg.validSymMtxVec(size(exp,1))
                error('Argument wrong size.');
            end
            
            if size(exp,1) == 1
                [pr,l,y] = pr.withPos(pr,exp);
            else
                [pr,Qs] = pr.newBlkPSD(size(exp));
                [pr,y] = pr.withEqs(exp-Q);
            end
        end
        
        function [pr,l,y] = withLor(pr,exp)
            if ~isa(exp,'msspoly')
                error('Argument must be an msspoly.');
            end
            
            if size(exp,1) == 1
                [pr,l,y] = pr.withPos(pr,exp);
            else
                [pr,l] = pr.newLor(size(exp));
                [pr,y] = pr.withEqs(exp(:)-l(:));
            end
        end
        
        
        function sol = optimize(pr,objective)
            objective = msspoly(objective);
            if ~realLinearInDec(pr,objective)
                error('Objective must be real and linear in dec. variables.');
            end
            
            %  First, construct structure with counts of SeDuMi
            %  variables.
            K = struct();
            K.f = pr.freeNum;
            K.l = pr.posNum;
            K.q = pr.lorDim;
            K.r = pr.rlorDim;
            K.s = pr.psdDim;
            
            KvarCnt = K.f+K.l+sum(K.q)+sum(K.r)+sum(K.s.^2);
            
            
            v = [ pr.freeVariables
                  pr.posVariables
                  pr.lorVariables
                  pr.rlorVariables ];
            
            vpsd = pr.psdVariables;
            
            vall = [v;vpsd];
            
            % Assign column numbers to v.
            psdVarNo = zeros(1,length(vpsd));
            psdVarNoSymm = zeros(1,length(vpsd));
            psdVarOff = 0;    % Progress in variables, storing
                              % upper triangle.
            psdRedVarOff = 0; % Progress in variables, storing
                              % entire matrix.
            for i = 1:length(pr.psdDim)
                n = pr.psdDim(i);
                m = n*(n+1)/2;
                psdVarNo(psdVarOff + (1:m)) = psdRedVarOff+mss_s2v(reshape(1:n^2,n,n));
                psdVarNoSymm(psdVarOff + (1:m)) = psdRedVarOff+mss_s2v(reshape(1:n^2,n,n)');
                psdVarOff = psdVarOff + m;
                psdRedVarOff = psdRedVarOff + n^2;
            end
            
            varNo = [ 1:length(v) length(v)+psdVarNo];
            varNoSymm = [ 1:length(v) length(v)+psdVarNoSymm];

            
            function [bs,As] = linearToSedumi(lin)
                [veq,peq,Ceq] = decomp(lin);
                constant = all(peq == 0,2);
                cnsti = find(constant);
                
                bs = -Ceq(:,cnsti);
                
                Aeq = Ceq(:,~constant)*peq(~constant,:);

                [~,vid] = isfree(vall);
                [~,veqid] = isfree(veq);
                veqIndices = mss_match(vid,veqid);
                
                % T*vall = veq;
                T = sparse(1:length(veq),veqIndices,ones(length(veq),1));
                
                [i,j,s] = find(Aeq*T);

                As = sparse(i,varNo(j),s,...
                            size(Aeq,1),KvarCnt);
            end
            
            [b,A] = linearToSedumi(pr.equations);
            [~,c] = linearToSedumi(objective);
            
            if all(b == 0)
                error('Trivial solution, x = 0.');
            end
            [x,y,info] = sedumi(A,b,c,K);
            
            if info.pinf, 
                primalSol = NaN*ones(size(length(varNo),1));
            else
                primalSol = x(varNo);
            end
            
            if info.dinf
                dualSol = NaN*ones(size(y));
                dualSlack = NaN*ones(size(primalSol));
            else
                dualSol = y;
                z = c'-A'*y;
                dualSlack = (z(varNo)+z(varNoSymm))/2;
            end

            sol = spotsqlsol(pr,info,objective,...
                             primalSol,dualSol,dualSlack);
        end
        
    end
end