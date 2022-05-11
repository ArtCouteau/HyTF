classdef system < handle
    %SYSTEM Main class of the heat transfer during H2 tank refueling solver
    % Author: Arthur Couteau
    
    properties
        % Input dictionaries
        dict simulation.dictionaries.dictionary
        % Control
        control simulation.control
        % Geometry
        geometry simulation.geometry
        % Hydrogen thermodynamics
        HydrogenThermodynamics simulation.HydrogenThermodynamics.HydrogenThermodynamics
        % Wall thermodynamics
        WallThermodynamics simulation.WallThermodynamics
        % FFTB solver
        FFTBSolver simulation.solvers.FFTBSolver
        % Reference to figure for post-processing
        fh
        % Video
        F
    end
    
    methods
        function obj = system()
            %SYSTEM Construct an instance of this class
            
            close all
            % Extract dictionaries from input files
            obj.extractDictFromInputFiles();
            % Initialize properties
            obj.control = simulation.control(obj);
            obj.geometry = simulation.geometry(obj);
            obj.HydrogenThermodynamics = simulation.HydrogenThermodynamics.HydrogenThermodynamics(obj);
            obj.WallThermodynamics = simulation.WallThermodynamics(obj);
            obj.FFTBSolver = simulation.solvers.FFTBSolver(obj);
            % Plot thermocouples
            obj.fh = figure('Visible','off');
            set(obj.fh, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
            subplot(2,2,1)
            hold on
            tmpEDR = obj.HydrogenThermodynamics.ExpDR;
            if (strcmp(obj.control.dataName,'custom'))
                plot(tmpEDR.inletCond.t,tmpEDR.inletCond.T)
            else
                for iThermo = 1:8
                    plot(tmpEDR.ExpData.data(:,1), tmpEDR.ExpData.data(:,5+iThermo)+273.15)
                end
                plot(tmpEDR.ExpData.data(:,1), tmpEDR.ExpData.data(:,20)+273.15)
            end
            % Video
            obj.F = getframe(obj.fh);
            
            % Set up output files
            obj.setOutputFiles();
        end
        
        function obj = run(obj)
        % Run a simulation
            
            % Time integration
            nTimeIter = 0;
            iFrame = 1;
            while (obj.control.tCur < obj.control.tEnd)
                % Update thermodynamic and transport properties for H2
                obj.HydrogenThermodynamics.update();
                % Iterative solver
                obj.FFTBSolver.solve();
                
                % Time control
                obj.control.tCur = obj.control.tCur + obj.control.dt;
                nTimeIter = nTimeIter + 1;
                if ((nTimeIter == 1) || (mod(nTimeIter,obj.control.tEnd/obj.control.dt/obj.control.nFrames) == 0))
                    obj.plotVariables();
                    obj.F(iFrame) = getframe(obj.fh);
                    iFrame = iFrame + 1;
                    obj.write();
                end
            end
        end
        function obj = postProcessing(obj)
        % Create plots and video from the results
        
            % Save last frame as picture
            if (obj.control.tCur == obj.control.tEnd)
                saveas(obj.fh, ['output' filesep obj.control.simName filesep obj.control.simName '.png'])
            end
            % Create video
            obj.createVideo();
        end
        function dict = findDict(obj,nameDict)
            foundDict = false;
            countDict = 1;
            while ((~(foundDict)) && (countDict <= size(obj.dict,2)))
                if (strcmp(obj.dict(1,countDict).name,nameDict))
                    dict = obj.dict(1,countDict);
                    foundDict = true;
                else
                    countDict = countDict + 1;
                end
            end

            % Error if entry is not found
            if (~(foundDict))
                error(['Dictionary ' nameDict ' not found'])
            end 
        end
    end
    
    methods (Access = private)
        function obj = extractDictFromInputFiles(obj)
        %EXTRACTDICTFROMINPUTFILES Read input files and extract the dictionaries

            % Control
            obj = extractDictFromFile(obj,['input' filesep 'control']);

            % Tank geometry
            obj = extractDictFromFile(obj,['input' filesep 'geometry']);

            function class_Obj = extractDictFromFile(class_Obj,inputArg)
            %EXTRACTDICTFROMFILE Extract dictionaries from input file
            %   inputArg is the name of the file

                str = fileread(inputArg);
                tok = regexp(str,'(\w+)\n\{(.+?)\}','tokens');
                for iDict = 1:size(tok,2)
                    class_Obj.dict(end+1) = ...
                        simulation.dictionaries.dictionary(tok{1,iDict}{1,1},tok{1,iDict}{1,2});
                end
            end
        end
        function obj = plotVariables(obj)
            % Plot
            set(0, 'currentfigure', obj.fh);
            subplot(2,2,1)
            hold on
            plot(obj.control.tCur,obj.HydrogenThermodynamics.T,'kx','MarkerSize',4) 
            xlim([0 obj.control.tEnd])
            xlabel('Time [s]')
            ylabel('Temperature [K]')
            title('Homogeneous Hydrogen temperature')
            subplot(2,2,2)
            hold on
            plot(obj.control.tCur,obj.HydrogenThermodynamics.p,'kx','MarkerSize',4)
            xlim([0 obj.control.tEnd])
            xlabel('Time [s]')
            ylabel('Temperature [K]')
            title('Homogeneous Hydrogen temperature')
            subplot(2,2,3)
            hold off
            plot(linspace(obj.geometry.RInternal,obj.geometry.RExternal,obj.FFTBSolver.HeatDiffSolver.NCells),obj.WallThermodynamics.T,'k')
            hold on
            plot([obj.geometry.RInternal,obj.geometry.RExternal],obj.HydrogenThermodynamics.T*ones(2,1),'k--')
            xlim([obj.geometry.RInternal obj.geometry.RExternal])
            xlabel('r [m]')
            ylabel('T [K]')
            title('Tank wall temperature profile')
            subplot(2,2,4)
            hold on
            plot(obj.control.tCur,obj.HydrogenThermodynamics.m,'kx')
            xlim([0 obj.control.tEnd])
            xlabel('Time [s]')
            ylabel('Mass [kg]')
            title('Hydrogen mass in tank')
            sgtitle(['t = ' num2str(obj.control.tCur)])
            drawnow
        end
        function obj = createVideo(obj)
        % Creates a video from F (plots through time)  
            writerObj = VideoWriter(['output' filesep obj.control.simName filesep obj.control.simName '.avi']);
            writerObj.FrameRate = 10;
            open(writerObj);
            for iF=1:length(obj.F)
                writeVideo(writerObj, obj.F(iF));
            end
            close(writerObj);
        end
        function obj = setOutputFiles(obj)
        %SETOUTPUTFILE Write initial conditions
            
            fid1 = fopen(['output' filesep obj.control.simName filesep 'output.dat'], 'w');
            fprintf(fid1, '%*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s\n', ...
                10,'Time [s]', ...
                10,'TH2 [K]', ...
                20,'pH2 [Pa]', ...
                10,'mH2 [kg]', ...
                10,'TInl [K]', ...
                15,'dmdt [kg/s]', ...
                15,'UInl [m/s]', ...
                10,'ReInl [-]', ...
                10,'NuFor [-]', ...
                10,'NuNat [-]', ...
                20,'kH2toW [W/m^2/K]', ...
                10,'Term1 [W]', ...
                10,'Q [W]', ...
                10,'Term3 [W]', ...
                10,'BETA [1/K]', ...
                15,'dpdt [Pa/s]', ...
                15,'#Iterations');
            fclose(fid1);
            fid2 = fopen(['output' filesep obj.control.simName filesep 'TWall.dat'], 'w');
            fclose(fid2);
        end
        function obj = write(obj)
        %WRITE Write simulation data to output file
            
            fid1 = fopen(['output' filesep obj.control.simName filesep 'output.dat'], 'a');
            fprintf(fid1,  '%*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f\n', ...
                10,obj.control.tCur, ...
                10,obj.HydrogenThermodynamics.T, ...
                20,obj.HydrogenThermodynamics.p, ...
                10,obj.HydrogenThermodynamics.m, ...
                10,obj.HydrogenThermodynamics.TInlet, ...
                15,obj.HydrogenThermodynamics.dmdtInlet, ...
                15,obj.HydrogenThermodynamics.UInlet, ...
                10,obj.HydrogenThermodynamics.ReInlet, ...
                10,obj.HydrogenThermodynamics.NuFor, ...
                10,obj.HydrogenThermodynamics.NuNat, ...
                20,obj.HydrogenThermodynamics.HTCGasToWall, ...
                10,obj.HydrogenThermodynamics.Term1, ...
                10,obj.HydrogenThermodynamics.QGasToWall, ...
                10,obj.HydrogenThermodynamics.Term3, ...
                10,obj.HydrogenThermodynamics.BETA, ...
                10,obj.HydrogenThermodynamics.dpdt, ...
                15,obj.FFTBSolver.nIterCur);
            fclose(fid1);
            fid2 = fopen(['output' filesep obj.control.simName filesep 'TWall.dat'], 'a');
            fprintf(fid2,'%.2f',obj.control.tCur);
            fprintf(fid2,'% .3f',obj.WallThermodynamics.T);
            fprintf(fid2,'\n');
            fclose(fid2);
        end
    end
end

