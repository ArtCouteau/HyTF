classdef control < handle
    %CONTROL Control parameters selected by the user
    
    properties
        % Simulation name 
        simName char
        % End of simulation - [s]
        tEnd (1,1) double
        % Time step - [s]
        dt (1,1) double
        % Current time - [s]
        tCur (1,1) double
        % 1D axisymmetric heat diffusion solver # of discretization cells
        NCellsHDS (1,1) double
        % FFTB solver tolerance
        tolFFTB (1,1) double
        % FFTB solver max # of iterations
        nIterMaxFFTB (1,1) double
        % Experimental data name
        dataName char
        % Post processing # of frames
        nFrames (1,1) double
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = control(system)
            %CONTROL Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Read data from dictionary
            tmpDict = obj.system.findDict('control');
            obj.simName = tmpDict.readChar('name');
            obj.dataName = tmpDict.readChar('dataSet');
            obj.tCur = 0;
            obj.tEnd = tmpDict.readDouble('tEnd');
            obj.dt = tmpDict.readDouble('dt');
            obj.NCellsHDS = tmpDict.readDouble('NCells');
            obj.tolFFTB = 1e-6;
            obj.nIterMaxFFTB = 20;
            obj.nFrames = tmpDict.readDouble('nFrames');
            
            % Create/clean output directory
            if (~(isfolder('output')))
                mkdir 'output'
            end
            if (~(isfolder(['output' filesep obj.simName])))
                mkdir(['output' filesep obj.simName])
            end
            copyfile(['input' filesep 'control'], ['output' filesep obj.simName])
            copyfile(['input' filesep 'geometry'], ['output' filesep obj.simName])
        end
    end
end

