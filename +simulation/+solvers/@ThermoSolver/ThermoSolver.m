classdef ThermoSolver < handle
    %THERMOSOLVER Thermodynamic solver
    %   Energy conservation + Real gas equation of state
    
    properties
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = ThermoSolver(system)
            %THERMOSOLVER Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Initialize properties
        end
        
        
        function [TH2,pH2,mH2] = solve(obj,HT,Q)
        % Returns the hydrogen temperature, pressure and mass, obtained by 
        % solving the energy conservation equation + EoS
        % The pressure is given by the inlet pressure during refueling, and
        % the mass is fixed after refueling
        %   -> HT is the Hydrogen thermodynamics and transport at previous time
        %      step
        %   -> Q is the heat flux from the Hydrogen to the wall
        
            if (obj.system.control.tCur < obj.system.HydrogenThermodynamics.ExpDR.inletCond.tFull)
                uInit = [HT.T, HT.m];
                uSol = fsolve(@(u) systemEq(obj, u, HT, Q),uInit,optimset('Display','none'));

                TH2 = uSol(1);
                pH2 = HT.pInlet;
                mH2 = uSol(2);
            else
                uInit = [HT.T, HT.p];
                uSol = fsolve(@(u) systemEqFull(obj, u, HT, Q),uInit,optimset('Display','none'));

                TH2 = uSol(1);
                pH2 = uSol(2);
                mH2 = HT.m;
            end
        end
    end
    
    methods (Access = private)
        function out = systemEq(obj, in, HT, Q)
        % System of equations during refueling: 
        % Energy conservation in the tank and equation of state

            % Variables
            tmpT = in(1);
            tmpm = in(2);

            % Hydrogen energy conservation
            out(1) = ...
                (tmpT - HT.T)/obj.system.control.dt*HT.CP*HT.m ...
              - Q ...
              - obj.system.geometry.V*HT.BETA*tmpT*HT.dpdt ...
              - (tmpm - HT.m)/obj.system.control.dt*(HT.HInlet + HT.UInlet^2/2 - HT.H);

            % Equation of state
            out(2) = (HT.p*obj.system.geometry.V)/(tmpm*tmpT*HT.R*HT.Z) - 1;

        end
        function out = systemEqFull(obj, in, HT, Q)
        % System of equations after refueling: 
        % Energy conservation in the tank and equation of state

            % Variables
            tmpT = in(1);
            tmpp = in(2);

            % Hydrogen energy conservation
            out(1) = ...
                (tmpT - HT.T)/obj.system.control.dt*HT.CP*HT.m ...
              - Q ...
              - obj.system.geometry.V*HT.BETA*tmpT*(tmpp - HT.p)/obj.system.control.dt;

            % Equation of state
            out(2) = (tmpp*obj.system.geometry.V)/(HT.m*tmpT*HT.R*HT.Z) - 1;

        end
    end
end

