classdef entry < handle
    %ENTRY Entry of a dictionary
    %   Detailed explanation goes here
    
    properties
        % Name of the entry
        name char
        % Value of the entry
        value char
    end
    
    methods
        function obj = entry(inputArg1,inputArg2)
            %ENTRY Construct an instance of this class
            %   inputArg1 is a string consisting of the name of the entry
            %   and its value
            obj.name = inputArg1;
            obj.value = inputArg2;
        end
    end
end

