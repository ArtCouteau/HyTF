classdef FFTBSolver < handle
    %FFTBSOLVER Flux Forward Temperature Back solver
    %   Iterative solver to couple the temperature and heat flux across the
    %   Hydrogen to wall boundary
    
    properties
        % Hydrogen thermodynamic solver
        ThermoSolver simulation.solvers.ThermoSolver
        % Heat diffusion solver
        HeatDiffSolver simulation.solvers.HeatDiffusionSolver
        % Solver tolerance
        tol (1,1) double
        % Solver max # of iterations
        nIterMax (1,1) double
        % # of iterations needed to convergence of current time step
        nIterCur (1,1) double
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = FFTBSolver(system)
            %FFTBSOLVER Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Initialize solvers
            obj.ThermoSolver = simulation.solvers.ThermoSolver(obj.system);
            obj.HeatDiffSolver = simulation.solvers.HeatDiffusionSolver(obj.system);
            % Initialize properties
            obj.tol = obj.system.control.tolFFTB;
            obj.nIterMax = obj.system.control.nIterMaxFFTB;
        end
        
        function obj = solve(obj)
        % Iterative solver
        
            % Get initial state
            iIter = 1;
            resTH2 = 1; resTW = 1;
            star = getStarState(obj);
            % Iteration 
            while (((resTH2 > obj.tol) || (resTW > obj.tol)) && (iIter < obj.nIterMax)) 
                tmpStar = star;
                % Update Hydrogen temperature
                [star.TH2,star.pH2,star.mH2] = obj.ThermoSolver.solve(obj.system.HydrogenThermodynamics, star.Q);
                % Update heat flux from Hydrogen to wall
                star.Q = obj.system.HydrogenThermodynamics.HTCGasToWall*obj.system.geometry.AInternal*(star.TW(1) - star.TH2);
                % Update wall temperature profile
                HTCWalltoAmb = 8;
                star.TW = obj.HeatDiffSolver.solve(obj.system.WallThermodynamics, star.TH2, obj.system.HydrogenThermodynamics.HTCGasToWall, HTCWalltoAmb);
                
                % Compute residuals
                resTH2 = abs(star.TH2 - tmpStar.TH2)/tmpStar.TH2;
                resTW = abs(star.TW(1) - tmpStar.TW(1))/tmpStar.TW(1);
                
                % Plot residuals
%                 set(0, 'currentfigure', obj.system.fh)
%                 subplot(2,2,4)
%                 hold on
%                 plot(iIter,resTH2,'kx')
%                 plot(iIter,resTW,'bx')
%                 set(gca,'YScale','log')
%                 xlim([1 obj.nIterMax])
%                 xlabel('# Iterations of FFTB solver')
%                 ylabel('Residuals [W]')
%                 title('Residuals over FFTB solver iterations')
%                 drawnow
                
                iIter = iIter + 1;
            end
            obj.nIterCur = iIter;
            
            % Save the converged star state
            obj.saveStarState(star);
        end
    end
    
    methods (Access = private)
        function starState = getStarState(obj)
        % Initialize star state
            
            starState.TH2 = obj.system.HydrogenThermodynamics.T;
            starState.pH2 = obj.system.HydrogenThermodynamics.p;
            starState.mH2 = obj.system.HydrogenThermodynamics.m;
            starState.Q = obj.system.HydrogenThermodynamics.QGasToWall;
            starState.TW = obj.system.WallThermodynamics.T;
        end
        function obj = saveStarState(obj,starState)
        % Save star state after the convergence is reached
            
            obj.system.HydrogenThermodynamics.T = starState.TH2;
            obj.system.HydrogenThermodynamics.p = starState.pH2;
            obj.system.HydrogenThermodynamics.dmdtInlet = (starState.mH2 - obj.system.HydrogenThermodynamics.m)/obj.system.control.dt;
            obj.system.HydrogenThermodynamics.m = starState.mH2;
            obj.system.HydrogenThermodynamics.QGasToWall = starState.Q;
            obj.system.WallThermodynamics.T = starState.TW;
        end
    end
end

