classdef WallThermodynamics < handle
    %WALLTHERMODYNAMICS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Wall temperature - [K]
        T double
        % Liner density - [kg/m^3]
        rhoLin (1,1) double
        % Liner thermal conductivity - [W/m/K]
        TCXLin (1,1) double
        % Liner specific heat capacity - [J/kg/K]
        CPLin (1,1) double
        % Liner heat diffusivity - [m^2/s]
        alphaLin (1,1) double
        % Carbon wrapping density - [kg/m^3]
        rhoWra (1,1) double
        % Carbon wrapping thermal conductivity - [W/m/K]
        TCXWra (1,1) double
        % Carbon wrapping specific heat capacity - [J/kg/K]
        CPWra (1,1) double
        % Carbon wrapping heat diffusivity - [m^2/s]
        alphaWra (1,1) double
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = WallThermodynamics(system)
            %WALLTHERMODYNAMICS Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Initialize properties-
            tmpDict = obj.system.findDict('factors');
            obj.TCXLin = tmpDict.readDouble('TCXLin')*0.36;
            obj.rhoLin = 947;
            obj.CPLin = 1880;
            obj.alphaLin = tmpDict.readDouble('alphaLin')*obj.TCXLin/obj.rhoLin/obj.CPLin;
            obj.TCXWra = tmpDict.readDouble('TCXWra')*1.5;
            obj.rhoWra = 1600;
            obj.CPWra = 1400;
            obj.alphaWra = tmpDict.readDouble('alphaWra')*obj.TCXWra/obj.rhoWra/obj.CPWra;
            obj.T = obj.system.HydrogenThermodynamics.TInlet*ones(obj.system.control.NCellsHDS,1);
        end
    end
end

