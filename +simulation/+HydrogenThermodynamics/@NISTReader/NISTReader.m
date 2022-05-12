classdef NISTReader < handle
    %NISTREADER Reads thermodynamical and transport properties from the
    %NIST database
    
    properties
        % REFPROP database
        RP
        % Absolute path to REFPROP folder
        RPPath char
        % Units
        iUnits
        % Mass/Mole fraction
        iMass
        % SATSPLN call
        iFlag
        % Fluid composition
        z
    end
    
    methods
        function obj = NISTReader()
            %NISTREADER Construct an instance of this class
            obj.RPPath = '/home/acouteau/Documents/1_PhD/1_Codes/0_Libraries/3_REFPROP/REFPROP-cmake/refprop';
            obj.RP = py.ctREFPROP.ctREFPROP.REFPROPFunctionLibrary(obj.RPPath);
            obj.iUnits = obj.RP.GETENUMdll(int8(0), 'MASS BASE SI').iEnum;  % Mass base SI units
            obj.iMass = int8(1);    % Output is in mass fraction
            obj.iFlag = int8(0);    % 0: don't call SATSPLN; 1: call SATSPLN
            obj.z = {1.0};          % Composition of the fluid
        end
        
        function out = getProperty(obj,fluidName,propName,T,p)
        %GETPROPERTY Return property from NIST database
            
            switch fluidName
                case 'Hydrogen'
                    FLDpath = [obj.RPPath '/FLUIDS/HYDROGEN.FLD'];
                case 'Air'
                    FLDpath = [obj.RPPath '/FLUIDS/AIR.PPF'];
            end

            rp = obj.RP.REFPROPdll ...
                    ( ...
                        FLDpath,'TP',propName, ...
                        obj.iUnits, obj.iMass, obj.iFlag, ...
                        T, p, obj.z ...
                    );
            if (~(isempty(char(rp.herr))))
                error(['Error in reading data from REFPROP:\n' char(rp.herr)])
            else
                tmpOutput = double(rp.Output);
                out = tmpOutput(1);
            end
        end
    end
end

