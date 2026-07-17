This directory contains 3 folders, each associated with a certain "stage" in the ML 3-DoF position control experiments.
The folders are:

1. 00_Z_1dctrl
	- 1D (i.e. vertical) position control for maglev + performance diagnostics, with coil current ratios (CCRs) as variable inputs
	- Purpose: Allow user to observe magnet's response to altered CCRs; i.e. **generate ML training data** for future 3D control
	- Important contents:
		1. `Z_1Dctrl.slx`	-	Simulink model for vertical levitation (w/ diagnostics & CCR inputs)
		2. `00_DAQ_Triggers`, 
		   `00_LAYOUTS_manual`	- 	Data acquisition and custom UIs, for use in ControlDesk during operation
		3. `00_PythonScripts`	- 	Python-ControlDesk interfaces, to automatically read and write variables during operation
						(i.e. **THIS IS THE AUTOMATED TRAINING DATA GENERATOR!**)
	- Important outputs:
		1. <EXPERIMENT NAME>\`Measurement data` folder
			^ This is the raw data that is processed by the contents of the `MATLAB Training` folder.
			Usage: COPY+PASTE ITS CONTENTS INTO THE `Matlab Training\Measurement Data\<YYYY-MM-DD>\` FOLDER.
			       Then, follow instructions in `MATLAB Training\00README` as necessary.



2. 01_Z_3dctrl
	- 3D position control for maglev, with XYZ positions as variable inputs, using specified wrench matrix/matrices (e.g. ML-generated ones).
	- Uses at least one wrench matrix to decide on the necessary coil currents for desired motion.
	- Important INPUTS:
		1. Wrench matrices in `Z_3Dctrl.slx` must be edited MANUALLY upon (re)obtaining the actual wrench matrices from data (e.g. with ML, which the `MATLAB Training` folder is for). Wrench scheduling is currently only configured to interpolate between 3 wrenches, and boundaries of each subregion must be configured manually as well.



3. Accel_00X
	- DOES NOT WORK. This is a (failed) experiment which had the goal of using a trained ML model that can reliably output a set 
	  of coil current ratios necessary to achieve some desired (user-inputted) acceleration of the levitated magnet. 
	  Unfortunately, such a ML model was not found.



Each folder contains:

- a Simulink control model
- a dSPACE ControlDesk interface, which deploys the Simulink model onto the controller
- (00_Z_1dctrl only) Python-ControlDesk interfaces (operated via Jupyter notebook), for automated handling of system inputs