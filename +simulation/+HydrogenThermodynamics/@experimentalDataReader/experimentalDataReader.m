classdef experimentalDataReader < handle
    %EXPERIMENTALDATAREADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Raw experimental data
        ExpData (1,1) struct
        % Treated experimental data
        inletCond (1,1) struct
        % Custom inlet conditions
        custom (1,1) struct
        % Reference to the simulation system
        system simulation.system
    end
    
    methods
        function obj = experimentalDataReader(system)
            %EXPERIMENTALDATAREADER Construct an instance of this class
            
            % Reference to system
            obj.system = system;
            % Initialize properties
            if (strcmp(obj.system.control.dataName,'custom'))
                obj.createCustomData();
            else
                obj.ExpData = importdata(['input' filesep 'sensorData' filesep obj.system.control.dataName '.txt']);
                obj.extractDataFromSet();
            end
            
        end
        
        function out = getInlVar(obj,varName)
        % Get inlet value of variable at current time
            
            out = getInlVarValue(obj,varName,obj.system.control.tCur);
        end
    end
    
    methods (Access = private)
        function obj = extractDataFromSet(obj)
        %EXTRACTDATAFROMSET Extract the experimental data corresponding to
        %refueling from the whole set

            t = obj.ExpData.data(:,1);
            T = obj.ExpData.data(:,20) + 273.15;
            p = obj.ExpData.data(:,2)*1e5;
            NExp = size(t,1);
            
            % Filter noise
            NFilter = ceil(NExp/200);
            coeffMA = ones(1,NFilter)/NFilter;
            avgP = filter(coeffMA,1,p);
            avgP(1:NFilter) = avgP(NFilter+1);
            avgT = filter(coeffMA,1,T);
            avgT(1:NFilter) = avgT(NFilter+1);
            
            % Filter delay
            dt = t(2)-t(1);
            obj.inletCond.fDelay = (NFilter-1)/2*dt;
            
            % Pressure ramp rate
            dpdt = gradient(avgP,dt);
            avgdpdt = filter(coeffMA,1,dpdt);
            avgdpdt(1:NFilter) = avgdpdt(NFilter+1);
            
            % Debugging
            figure('Visible','off')
            subplot(1,2,1)
            plot(t,T)
            hold on
            plot(t - obj.inletCond.fDelay,avgT)
            subplot(1,2,2)
            plot(t,p)
            hold on
            plot(t - obj.inletCond.fDelay,avgP)
            yyaxis right
            plot(t,avgdpdt)
            saveas(gcf,['output' filesep obj.system.control.simName filesep 'inletData.png'])
            
            % Extract data starting at refueling
            obj.inletCond.t = t;
            obj.inletCond.T = avgT;
            obj.inletCond.p = avgP;
            obj.inletCond.dpdt = avgdpdt;
            [~,indFull] = max(avgP);
            obj.inletCond.tFull = indFull*dt;
        end
        function obj = createCustomData(obj)
        %CREATECUSTOMDATA Creates custom inlet data from user input
        
            tmpDict = obj.system.findDict('customData');
            pS = tmpDict.readDouble('pStart');
            pE = tmpDict.readDouble('pEnd');
            TA = tmpDict.readDouble('TAmb');
            TC = tmpDict.readDouble('TCool');
            tTbot = tmpDict.readDouble('tTbot');
            obj.inletCond.tFull = tmpDict.readDouble('tFull');
            
            obj.inletCond.t = 0:obj.system.control.dt:obj.inletCond.tFull;
            obj.inletCond.p = interp1([0 obj.inletCond.tFull],[pS pE],obj.inletCond.t);
            iTbot = find(obj.inletCond.t <= tTbot,1,'last');
            if (tTbot == 0)
                obj.inletCond.T = [TA interp1([tTbot obj.inletCond.tFull],[TC TC],obj.inletCond.t(iTbot+1:end))];
            else
                obj.inletCond.T = [interp1([0 tTbot],[TA TC],obj.inletCond.t(1:iTbot)) ...
                    interp1([tTbot obj.inletCond.tFull],[TC TC],obj.inletCond.t(iTbot+1:end))];
            end
        end
        function out = getInlVarValue(obj,varName,time)
            switch varName
                case {'p','T'}
                    fDelay = obj.inletCond.fDelay;
                case 'dpdt'
                    fDelay = 2*obj.inletCond.fDelay;
            end
            
            if (time <= obj.inletCond.t(end))
                out = interp1(obj.inletCond.t,obj.inletCond.(varName),max(time,fDelay));
            else
                out = obj.inletCond.(varName)(end);
            end
        end
    end
end

