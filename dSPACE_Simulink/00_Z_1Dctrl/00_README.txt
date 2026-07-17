
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~ Important contents of this directory: ~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	1. `Z_1Dctrl.slx`	-	Simulink model for vertical levitation (w/ diagnostics & CCR inputs)
	2. `00_DAQ_Triggers`, 
	   `00_LAYOUTS_manual`	- 	Data acquisition and custom UIs, for use in ControlDesk during operation
	3. `00_PythonScripts`	- 	Python-ControlDesk interfaces, to automatically read and write variables during operation
					(i.e. **THIS IS THE AUTOMATED TRAINING DATA GENERATOR!**)
	

~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~ HOW TO USE: ~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~

1. Build the Simulink model into machine-readable code
	a. Press CTRL+B within Simulink to build `z_1dctrl.sdf`, which will be deployed to the dSPACE controller via ControlDesk.

2. Create/open a Project+Experiment in ControlDesk
	a. (see SOP for creating/opening a project+experiment, and deploying `z_1dctrl.sdf` onto the controller)
	b. Import the GUIs for operating the levitation device via ControlDesk.
		i.   Under the `Layouting` toolbar, press `Import Linked Layout` and import all of the layouts in `00_Z_1Dctrl\00_LAYOUTS_manual`.
		     These should include:
			- LAYOUT_MagnetCustomize.lax		(For customizing dimensions & magnetic properties of the cylindrical magnet)
			- LAYOUT_signal_quality_SMOOTHEd.lax	(For observing the laser sensor precisions, both in and out of levitation)
			- LAYOUT_stability_diagnosis.lax	(For observing & empirically tuning the parameters associated with stability detection)
			- LAYOUT_status_monitoring.lax		(Main interface for operating the levitation, including detailed diagnostics associated
								with calibrations & automatic data recording (see below))
			- LAYOUT_z_PID_tuning.lax		(For manually tuning the feedforward and PID components of the vertical controller)
	c. Try to levitate the magnet to make sure that everything's working so far! (See the SOP for details)

3. (If a new Project was created) Set up the data recorder in ControlDesk
	a. Import the data recorder variables
		i.   Under `Measurement configuration` > `Recorders` > `Recorder 1`, delete any variables in the `Variable` list
		     that were added automatically by the software (i.e. all of them, if this is a new project). Pin this tab for
		     the time being so it doesn't disappear.
		ii.  Under `Variables`, press the `Imports favorites` button (next to the "path" bar at the top).
		iii. Import `Faves.txt`, located in the `00_Z_1Dctrl\00_DAQ_Triggers` folder. The variables should now appear in the Favorites
		     list under `Variables`.
		iv.  Highlight all of the variables in the Favorites list, and drag&drop them into the emptied `Recorder 1`'s Variable list.
	b. Import the Start/Stop conditions for triggered recording
		i.   Under `Measurement configuration` > `Recorders` > `Recorder 1`, right click on `Recorder 1` and go to its Properties.
		ii.  Under `Start condition`, enable `Use start trigger`.
		     Under `Stop condition`, set `Type` to `Trigger`.
		iii. Under `Start condition`, press the [...] button for `Trigger rule`. Import `Start Record.txt`, located in the 
		     `00_Z_1Dctrl\00_DAQ_Triggers` folder. Click on the line that appears in the `Logic  | Condition` table, and hit OK.
		iv.  Under `Stop condition`, press the [...] button for `Trigger rule`. Import `Stop Record.txt`, located in the 
		     `00_Z_1Dctrl\00_DAQ_Triggers` folder. Click on the line that appears in the `Logic  | Condition` table, and hit OK.
	c. Test that the data recorder + automatic Start/Stop triggers are working properly!
		i.   Press `Start Triggered` under the `Home` toolbar.
		ii.  Levitate the magnet for a bit, then turn on the "emergency stop" so it falls back down to the platform. Repeat a few times.
		iii. Press `Stop Recording` to end the automated recording.
		iv.  If everything is working properly, ControlDesk should have created SEVERAL recording files (e.g. `rec1_0001.mf4`, 
		     `rec2_0002.mf4`, etc.) in the `00_Z_1Dctrl\<EXPERIMENT_NAME>\Measurement Data` folder. Each file contains time-series
		     data recordings associated with a continuous period for which the automated recording conditions were met (see:
		     the `Recording?` line in the time-series plot in `LAYOUT_status_monitoring`).

4. Make sure Python-ControlDesk interface is working
	a. Open `Anaconda Prompt`, and navigate to the `00_PythonScripts` folder.
	   Example:
		Copy the full path in explorer.exe, and paste "cd /d D:\<THE REST OF THE PATH>\00_PythonScripts" (without quotes)
		into the Anaconda prompt (where the "/d" flag allows navigation to a different drive). 
		Hit Enter to navigate to the specified folder.
	b. Run Jupyter, and open the "Maglev_TrainingDataGenerator.ipynb" notebook.
	   Example:
		Type "jupyter lab" (newer; recommended) or "jupyter notebook" (legacy interface; support may end soon) into the Anaconda
		prompt, and hit Enter to open Jupyter Lab/Notebook in a browser window.
		Within the Jupyter Lab/Notebook instance, navigate to "Maglev_TrainingDataGenerator.ipynb" and open it.
	c. Run the code blocks underneath the "Initialize Python-ControlDesk interface" header. If they run without errors, the
	   connection is successful.

5. Generate training data!
	a. Run the code blocks to define ALL functions & variables (i.e. everything until the "Run Levitation!" heading).
	b. Run calibrations (if necessary-- i.e. if the sensors, aluminum platform, etc. have been adjusted in any way since the last calibration).
		i.   If the Simulink model was rebuilt and redeployed via ControlDesk, make sure to reconnect Python first.
		ii.  Run `calibrate_z` and `calibrate_xy`, then `get_calibration_params()` to print & save the measured calibration parameters.
		iii. Run `set_calibration_params()` to apply the measured params, if necessary. (Manual input; copy paste from the above step.)
		iv.  (To permanently save calibration params without needing to manually input them every time) Paste the calibration parameters
		     into their respective Constant blocks in the Simulink algorithm.)
		     (!!!!) BE SURE TO APPLY THIS TO SIMULINK CONTROL ALGORITHMS IN OTHER FOLDERS AS WELL! THIS STEP IS _NOT_ AUTOMATED. (!!!!)
	d. Run the code block under the "Data-gathering loop:" heading!
		i.   Prior to running, make sure that `Home` > `Start Triggered` has been enabled in ControlDesk so that data is recorded.
		ii.  Sit back and relax while the training data is recorded! (Be aware that, rarely, manual retrieval of the magnet may be 
		     needed if the Python script is unable to automatically recover a lost magnet on its own.)

6. Next step: Use the training data!
	a. Copy-paste all relevant data recordings into `00_WORKSTATION\MATLAB Training\Measurement Data\<YYYY-MM-DD>` (for the date of recording).
	b. See the readme file in the `MATLAB Training` folder for the rest of this next step.


