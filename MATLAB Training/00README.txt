This directory contains many MATLAB functions and scripts. These are used for:
	- processing the automatically-generated training data from the `dSPACE_Simulink\00_Z_1Dctrl` folder
	- tuning, training, and using the final machine learning models based on these training data, to generate wrench matrix/matrices
	- (general) Reading and analyzing recordings associated with `dSPACE_Simulink\01_Z_3Dctrl` (i.e. 3-DoF levitation using said wrench matrices)

USAGE:

0. (REQUIRES TRAINING DATA) Run `wrenchgenerator_00_generatedataset.mlx` to process the dataset into a single table.
	OUTPUT: `alldata.mat`.
1. Run `wrenchgenerator_01_tweakdataset.mlx` to tweak the formatting of `alldata.mat` for use in training.
	OUTPUT: `alldata_appended.mat`.
2. Run `wrenchgenerator_02_chunk_the_dataset.mlx` to define and visualize "chunks"/"subregions" within the dataset. The number and definitions of subregions are currently handled manually based on where the levitation dynamics deviate the most.
3. Run `wrenchgenerator_03_BayesianOptimizer.mlx` to automatically tune network hyperparameters for each subregion.
	NOTE:	Currently equipped to handle one subregion at a time. Slight edits are necessary when changing to different subregions; see the script itself for more details.
	OUTPUT:	Table(s) of Bayesian tuning process, showing the hyperparameters yielding the best performance and/or computation time. Not saved.
4. Based on the optimal hyperparameters in step 3, train the "combined network" (i.e. a cell array of networks, referred to as a "netracell" in the code), and use the trained networks to generate a wrench matrix associated with that subregion. This can be done with:
	4a: `wrenchgenerator_04a_chunk_trainer_and_wrench_obtainer_AUTOMATED.mlx`
		^ Automatically trains + saves networks for ALL subregions. Generates wrench matrices for one subregion at a time (requires manual loading of each subregion's "netracell" into the MATLAB workspace).
	4b: `wrenchgenerator_04b_chunk_trainer_and_wrench_obtainer.mlx`
		^ The manual version of 4a. Trains + saves networks for one subregion at a time
	NOTE:	Each of 4a and 4b have hyperparameters listed, which they use to train networks. Replace these hyperparams with those found in Step 3.
	OUTPUT:	- Trained "combined" networks!
		- Wrench matrix for each subregion!


And with that, the wrench matrices can be applied to the 3D control algorithm in `dSPACE_Simulink\01_Z_3Dctrl_ML`!


5(?). If necessary, see `wrenchgenerator_10_view_experiments` and `wrenchgenerator_11_fancyplot` for analyses of (previous) 3-DoF levitation experiments. May be useful as a "base" for creating your own journal-quality figures!