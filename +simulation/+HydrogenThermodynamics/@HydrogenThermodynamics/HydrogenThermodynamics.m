classdef HydrogenThermodynamics < handle
    %HYDROGENTHERMODYNAMICS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Hydrogen temperature - [K]
        T (1,1) double
        % Hydrogen pressure - [Pa]
        p (1,1) double
        % Pressure ramp rate - [Pa/s]
        dpdt (1,1) double
        % Hydrogen density - [kg/m^3]
        rho (1,1) double
        % Hydrogen mass - [kg]
        m (1,1) double
        % Hydrogen enthalpy - [J/kg]
        H (1,1) double
        % Hydrogen specific heat capacity - [J/kg/K]
        CP (1,1) double
        % Hydrogen gas constant - [J/kg/K]
        R (1,1) double
        % Hydrogen compressibility factor - [-]
        Z (1,1) double
        % Hydrogen volume expansivity - [1/K]
        BETA (1,1) double
        % Hydrogen thermal conductivity - [W/m/K]
        TCX (1,1) double
        % Hydrogen viscosity - [Pa*s]
        VIS (1,1) double
        % Experimental data reader
        ExpDR simulation.HydrogenThermodynamics.experimentalDataReader
        % Inlet temperature - [K]
        TInlet (1,1) double
        % Inlet pressure - [Pa]
        pInlet (1,1) double
        % Inlet enthalpy - [J/kg]
        HInlet (1,1) double
        % Inlet mass flow rate - [kg/s]
        dmdtInlet (1,1) double
        % Inlet velocity - [m/s]
        UInlet (1,1) double
        % Inlet Reynolds number - [-]
        ReInlet (1,1) double
        % Forced Nusselt number - [-]
        NuFor (1,1) double
        % Natural Nusselt number - [-]
        NuNat (1,1) double
        % Heat transfer coefficient to the tank wall - [W/m^2/K]
        HTCGasToWall (1,1) double
        % Term 1 in energy equation - [W]
        Term1 (1,1) double
        % Heat flux to the tank wall - [W]
        QGasToWall (1,1) double
        % Term 3 in energy equation - [W]
        Term3 (1,1) double
        % Ambient temperature - [K]
        TAmb (1,1) double
        % NIST database
        NISTReader simulation.HydrogenThermodynamics.NISTReader
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = HydrogenThermodynamics(system)
            %HYDROGENTHERMODYNAMICS Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Initialize properties
            obj.NISTReader = simulation.HydrogenThermodynamics.NISTReader();
            obj.ExpDR = simulation.HydrogenThermodynamics.experimentalDataReader(system);
            obj.TInlet = obj.ExpDR.getInlVar('T');
            obj.readInitialTemp();
            obj.pInlet = obj.ExpDR.getInlVar('p');
            obj.p = obj.pInlet;
            obj.HInlet = obj.NISTReader.getProperty('Hydrogen','H',obj.TInlet,obj.pInlet);
            obj.rho = obj.NISTReader.getProperty('Hydrogen','D',obj.T,obj.p);
            obj.m = obj.rho*obj.system.geometry.V;
            obj.updateProperties();
        end
        
        function obj = update(obj)
        % Updates H2 in tank by computing thermodynamic and transport 
        % properties according to T and p

            % Update inlet temperature and pressure
            obj.TInlet = obj.ExpDR.getInlVar('T');
            obj.pInlet = obj.ExpDR.getInlVar('p');
            obj.HInlet = obj.NISTReader.getProperty('Hydrogen','H',obj.TInlet,obj.pInlet);
            % Update rho and dpdt
            obj.rho = obj.m/obj.system.geometry.V;
            obj.dpdt = obj.ExpDR.getInlVar('dpdt');
            % Update properties
            obj.updateProperties();
            obj.NusseltLaw();
            
            % Compute terms in the energy equation (graph output)
            obj.Term1 = obj.system.geometry.V*obj.BETA*obj.T*obj.dpdt;
            obj.Term3 = obj.dmdtInlet*(obj.HInlet + obj.UInlet^2/2 - obj.H);
        end
    end
    
    methods (Access = private)
        function obj = readInitialTemp(obj)
            if (strcmp(obj.system.control.dataName,'custom'))
                obj.T = obj.TInlet;
                obj.TAmb = obj.TInlet;
            else
                obj.T = mean(obj.ExpDR.ExpData.data(1,6:13)) + 273.15;
                obj.TAmb = obj.ExpDR.ExpData.data(1,4) + 273.15;
            end
                
        end
        function obj = updateProperties(obj)
            %METHOD1 Update thermodynamical and transport properties,
            %reading from NIST database
            for iProp = {'H','CP','R','Z','BETA','TCX','VIS'}
                obj.(char(iProp)) = ...
                    obj.NISTReader.getProperty('Hydrogen',(char(iProp)),obj.T,obj.p);
            end
        end
        function obj = NusseltLaw(obj)
        % Returns the heat transfer coefficient between H2 and wall

            % --- Forced convection --- 
            % Get inlet velocity
            rhoInlet = obj.NISTReader.getProperty('Hydrogen','D',obj.TInlet,obj.pInlet);
            if (obj.dmdtInlet > 0)
                obj.UInlet = obj.dmdtInlet/rhoInlet/obj.system.geometry.AInlet;
            else
                obj.UInlet = 0;
            end
            % Inlet Reynolds number
            VISInlet = obj.NISTReader.getProperty('Hydrogen','VIS',obj.TInlet,obj.pInlet);
            obj.ReInlet = rhoInlet*obj.UInlet*2*obj.system.geometry.RInlet/VISInlet;
            % Nusselt correlation (TODO: -> 2 is a factor to fit experimental results)
            obj.NuFor = 2*1.5*(obj.system.geometry.RInlet/obj.system.geometry.RInternal)^(0.5)*obj.ReInlet^0.67;
            HTCFor = obj.TCX*obj.NuFor/(2*obj.system.geometry.RInternal);

            % --- Natural convection ---
            g = 9.81;   % [m/s^2]
            Gr = (g*obj.BETA*(obj.T - obj.system.WallThermodynamics.T(1))*obj.rho^2*obj.system.geometry.RInternal^3)/(obj.VIS^2);
            Pr = (obj.VIS*obj.CP)/obj.TCX;
            % Making sure that Ra is positive
            if (Gr <= 0)
                Ra = 0;
            else
                Ra = Gr*Pr;
            end
            % Nusselt correlation
            obj.NuNat = 0.104*Ra^0.352;
            HTCNat = obj.TCX*obj.NuNat/(2*obj.system.geometry.RInternal);

            % Overall correlation
            obj.HTCGasToWall = HTCFor+ HTCNat;
        end
    end
end

