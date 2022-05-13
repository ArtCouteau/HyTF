# HyTF

A solver to study heat transfer in high pressure hydrogen tank fillings

Requires:

```text
Matlab with the Optimization toolbox
NIST Refprop database (version >= 9.1)
```

## Installation

This software is under free license, however it requires both Matlab and an access to the NIST Refprop database. To access Refprop from Matlab, one needs to link it using the Python wrapper provided by NIST.

### Installing Refprop

#### Windows

Use the installer provided by NIST when buying license

#### OSX and Linux

On OSX and Linux, you have to build the Refprop from scratch. You need access to a Windows machine with Refprop installed, to have access to the `FORTRAN`, `FLUIDS` and `MIXTURES` folders. NIST provide a cmake build system to this extent and instructions on how to install and build at [REFPROP-cmake](https://github.com/usnistgov/REFPROP-cmake)

### Enabling Python on Matlab

Linking Python to Matlab is done using the `pyenv` command. In Matlab command line, type

```matlab
pyenv('Version','/path/to/python/executable')
```

It should display something like (here on UNIX)

```matlab
  PythonEnvironment with properties:

          Version: "3.9"
       Executable: "/path/to/python/folder/bin/python"
          Library: "/path/to/python/folder/lib/libpython3.9.so"
             Home: "/path/to/python/folder"
           Status: NotLoaded
    ExecutionMode: InProcess
```

### Python wrapper for Matlab

NIST provides instructions on how to install the Python wrapper for Matlab at [Python wrapper Matlab](https://github.com/usnistgov/REFPROP-wrappers/tree/master/wrappers/MATLAB). You need a compatible [Python version for Matlab](https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/support/sysreq/files/python-compatibility.pdf). I personally use a [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html#) environment, with the Python wrapper installed from `pip` (recommended) or [source](https://pypi.org/project/ctREFPROP/#files).

### Checking the installation

You can check if the installation is complete by typing in Matlab command line

```matlab
>> RP = py.ctREFPROP.ctREFPROP.REFPROPFunctionLibrary('/path/to/Refprop/library');
>> RP.RPVersion()

ans =

  Python str with no properties.

    10.0
```

Setup a first function call as

```matlab
>> iUnits = RP.GETENUMdll(int8(0), 'MASS BASE SI').iEnum;  % Mass base SI units
>> iMass = int8(1);    % Output is in mass fraction
>> iFlag = int8(0);    % 0: don't call SATSPLN; 1: call SATSPLN
>> z = {1.0};          % Composition of the fluid (1.0: pure fluid)
>> rp = RP.REFPROPdll ...
    ( ...
        'Hydrogen','TP','D', ...
        iUnits, iMass, iFlag, ...
        300, 1e6, z ...
    );
if (~(isempty(char(rp.herr))))
    error(['Error in reading data from REFPROP:\n' char(rp.herr)])
else
    tmpOutput = double(rp.Output);
    out = tmpOutput(1)
end
```

Which should give the following output

```matlab
out =

    0.8035
```

#### Quick fix in case of **[SETUP error 101]**

Refprop should find the `FLUIDS` directory but you might (on OSX and UNIX) end up with an error code like

```matlab
[SETUP error 101] Error in opening file for component 1: filename = Hydrogen.FLD
```

In this case, you can specify the absolute path to the `HYDROGEN.FLD` file to the `REFPROPdll` function

```matlab
>> FLDPath = '/path/to/Refprop/FLUIDS/'
>> rp = obj.RP.REFPROPdll ...
    ( ...
        [FLDPath 'HYDROGEN.FLD'],'TP','D', ...
        obj.iUnits, obj.iMass, obj.iFlag, ...
        300, 1e6, obj.z ...
    );
```

#### Refprop functions documentation

You can find the Refprop functions documentation [here](https://refprop-docs.readthedocs.io/en/latest/DLL/high_level.html#)

## Run

### Update NISTReader with your path to Refprop

Naviguate to `+simulation/+HydrogenThermodynamics/@NistReader` and update the path to Refprop in the class constructor (line 23)

```matlab
obj.RPPath = '/path/to/refprop';
```

### Run a simulation

The configuration files are in the `input` folder: `control` contains the general parameters and `geometry` information on the tank. As the code needs the data of the incoming hydrogen flow, you can select experimental data (the dataset `190821_f70MPa_01` is made available in `input/sensorData`) or create custom data by filling the desired value in the `custom` dictionary.

```text
dataSet 190821_f70MPa_01
OR
dataSet custom
```

Once you have set your configuration, you can run the code by simply typing

```matlab
>> run main
```

It will create a folder `output/<name>` containing the simulation output, the input files used to run the simulation and some post processed graphs
