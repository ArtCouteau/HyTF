classdef dictionary < handle
    %DICTIONARY Input files are organized as dictionaries with name and
    %entries
    
    properties
        % Name of the dictionary
        name char
        % Entries of the dictionary
        entries simulation.dictionaries.entry
    end
    
    methods
        function obj = dictionary(name,string)
            %DICTIONARY Construct an instance of this class
            %   name is the name of the dictionary
            %   string is the entries string
            obj.name = name;
            tokDict = regexp(string,'(\w+)\s+(\w+\.?(\d+)?)','tokens');
            % Loop over all entries
            for iEntry = 1:size(tokDict,2)
                obj.entries(iEntry) = ...
                    simulation.dictionaries.entry(tokDict{1,iEntry}{1,1},tokDict{1,iEntry}{1,2});
            end
        end
        
        function value = readDouble(obj,nameEntry)
        %READDOUBLE Read the entry value defined by nameEntry and convert 
        %it to double
            tmpEntry = findEntry(obj,nameEntry);
            value = str2double(tmpEntry.value);
        end
        
        function value = readChar(obj,nameEntry)
        %READCHAR Read the entry value defined by nameEntry
            tmpEntry = findEntry(obj,nameEntry);
            value = tmpEntry.value;
        end
    end
    
    methods (Access = private)
        function entry = findEntry(obj, nameEntry)
        %FINDENTRY Return the entry defined by nameEntry
            foundEntry = false;
            countEntry = 1;
            while ((~(foundEntry)) && (countEntry <= size(obj.entries,2)))
                if (strcmp(obj.entries(1,countEntry).name,nameEntry))
                    entry = obj.entries(1,countEntry);
                    foundEntry = true;
                else
                    countEntry = countEntry + 1;
                end
            end
            
            % Error if entry is not found
            if (~(foundEntry))
                error(['Entry ' nameEntry ' not found in dictionary ' ...
                    obj.name])
            end
        end
    end
end

