classdef HeatDiffusionSolver < handle
    %HEATDIFFUSIONSOLVER 1D axisymmetric heat diffusion solver
    %   Radial solver, with heat flux boundary conditions on each side,
    %   multi-layered materials
    %   The following system of equations is solved:
    %       dT/dt = omega*(A*T + b)
    %   Where omega, A and b are matrices and vector defined by the choice
    %   of discretization scheme and boundary conditions
    
    properties
        % # of discretization cells
        NCells (1,1) double
        % # of discretization cells in liner region
        NLin (1,1) double
        % # of discretization cells in carbon wrapping region
        NWra (1,1) double
        % Radii of the cell centers - [m]
        rCells double
        % Radial increment in liner region - [m]
        drLin (1,1) double
        % Radial increment in carbon wrapping region - [m]
        drWra (1,1) double
        % Solver matrix omega 
        omega double
        % Solver matrix A
        A double
        % Solver vector b
        b double
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = HeatDiffusionSolver(system)
            %HEATDIFFUSIONSOLVER Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Initialize properties
            tmpG = obj.system.geometry;
            obj.NCells = obj.system.control.NCellsHDS;
            obj.NLin = floor(obj.NCells*(tmpG.RMatBound - tmpG.RInternal)/(tmpG.RExternal - tmpG.RInternal));
            obj.NWra = obj.NCells - obj.NLin;
            obj.drLin = (tmpG.RMatBound - tmpG.RInternal)/obj.NLin;
            obj.drWra = (tmpG.RExternal - tmpG.RMatBound)/obj.NWra;
            obj.rCells = [linspace(tmpG.RInternal + 0.5*obj.drLin, tmpG.RMatBound - 0.5*obj.drLin, obj.NLin)'; ...
                          linspace(tmpG.RMatBound + 0.5*obj.drWra, tmpG.RExternal - 0.5*obj.drWra, obj.NWra)'];
            % Matrices initialization
            tmpWT = obj.system.WallThermodynamics;
            drDiag = [obj.drLin*ones(obj.NLin,1); obj.drWra*ones(obj.NWra,1)];
            alphaDiag = [tmpWT.alphaLin*ones(obj.NLin,1); tmpWT.alphaWra*ones(obj.NWra,1)];
            gammaDiag = obj.rCells./drDiag;
            % --- Omega ---
            omegaDiag = alphaDiag./(obj.rCells.*drDiag);
            obj.omega = spdiags(omegaDiag,0,obj.NCells,obj.NCells);
            % --- A ---
            obj.A = spdiags([([gammaDiag(2:end); 1] - 1/2) -2*gammaDiag ([1; gammaDiag(1:end-1)] + 1/2)], -1:1, obj.NCells, obj.NCells);
            % Materials boundary
            kappa = (obj.drWra*tmpWT.TCXLin)/(obj.drLin*tmpWT.TCXWra);
            obj.A(obj.NLin,obj.NLin) = -(2*gammaDiag(obj.NLin) - (gammaDiag(obj.NLin) + 1/2)*(kappa - 1)/(kappa + 1));
            obj.A(obj.NLin,obj.NLin+1) = (gammaDiag(obj.NLin) + 1/2)*2/(kappa + 1);
            obj.A(obj.NLin+1,obj.NLin) = (gammaDiag(obj.NLin+1) - 1/2)*2*kappa/(kappa + 1);
            obj.A(obj.NLin+1,obj.NLin+1) = -(2*gammaDiag(obj.NLin+1) + (gammaDiag(obj.NLin+1) - 1/2)*(kappa - 1)/(kappa + 1));
            % --- b ---
            obj.b = sparse(zeros(obj.NCells,1));
        end
        
        function T = solve(obj,WT,TH2,HTCg2w,HTCw2a)
        % Returns the wall temperature profile
        % The pressure is given by the inlet pressure during refueling, and
        % the mass is fixed after refueling
        %   -> WT is the Wall thermodynamics and transport at previous time
        %   step
        %   -> TH2 is the Hydrogen temperature
        %   -> HTCg2w is the heat transfer coefficient from the Hydrogen to 
        %   the wall
        %   -> HTCw2a is the heat transfer coefficient from the wall to the
        %   ambient air
            
            updateMatricesBC(obj,WT,TH2,HTCg2w,HTCw2a);
            T = fsolve(@(u) heatDiffusionSystemOfEqs(obj, u, WT), WT.T, optimset('Display','none'));
        end
    end
    
    methods (Access = private)
        function obj = updateMatricesBC(obj,WT,TH2,HTCg2w,HTCw2a)
        % Update solver matrices according to boundary conditions
            
            drDiag = [obj.drLin*ones(obj.NLin,1); obj.drWra*ones(obj.NWra,1)];
            gammaDiag = obj.rCells./drDiag;
        
            Nu_drg2w = HTCg2w*obj.drLin/WT.TCXLin;
            deltag2w = (1 - 0.5*Nu_drg2w)/(1 + 0.5*Nu_drg2w);
            Nu_drw2a = HTCw2a*obj.drWra/WT.TCXWra;
            deltaw2a = (1 - 0.5*Nu_drw2a)/(1 + 0.5*Nu_drw2a);

            obj.A(1,1) = -(2*gammaDiag(1) - (gammaDiag(1) - 1/2)*deltag2w);
            obj.A(obj.NCells,obj.NCells) = -(2*gammaDiag(obj.NCells) - (gammaDiag(obj.NCells) + 1/2)*deltaw2a);
            obj.b(1) = (gammaDiag(1) - 1/2)*Nu_drg2w/(1 + 0.5*Nu_drg2w)*TH2;
            obj.b(obj.NCells) = (gammaDiag(obj.NCells) + 1/2)*Nu_drw2a/(1 + 0.5*Nu_drw2a)*obj.system.HydrogenThermodynamics.TAmb;

        end
        function out = heatDiffusionSystemOfEqs(obj, in, WT)
        % Solve implicitely the system of equations
        %   dT/dt = omega*(A*in + b)

            out = (in - WT.T)/obj.system.control.dt - obj.omega*(obj.A*in + obj.b);
        end
    end
end

