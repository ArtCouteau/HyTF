classdef geometry < handle
    %GEOMETRY Geometry of the Hydrogen tank
    
    properties
        % Tank volume - [m^3]
        V (1,1) double
        % Internal radius - [m]
        RInternal (1,1) double
        % Internal exchange area - [m^2]
        AInternal (1,1) double
        % External radius - [m]
        RExternal (1,1) double
        % External exchange area - [m^2]
        AExternal (1,1) double
        % Material boundary radius - [m]
        RMatBound (1,1) double
        % Inlet radius - [m]
        RInlet (1,1) double
        % Inlet area - [m^2]
        AInlet (1,1) double
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = geometry(system)
            %GEOMETRY Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            
            % TODO -> read data from geometry file
            % EMPA tank
            obj.V = 0.036;
            obj.RInternal = 0.1294;
            obj.RMatBound = 0.1354;
            obj.RExternal = 0.1604;
            hCylinder = obj.V/(pi*obj.RInternal^2);
            % TODO -> 0.77 is factor to account for heat transfer through aluminium bosses
            obj.AInternal = 0.77*2*pi*obj.RInternal*hCylinder;
            
            tmpDict = obj.system.findDict('geometry');
            obj.RInlet = tmpDict.readDouble('Rinl');
            obj.AInlet = pi*obj.RInlet^2;
        end
    end
end

