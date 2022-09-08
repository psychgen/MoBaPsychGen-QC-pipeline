## Contents
This subdirectory contains python scripts that can be used to select samples using from PC plots.
These were the original scripts used during the QC and have since been replaced with Rscripts. We are including the scripts in the reposatory in case they are referenced in the qc-modules. 

* [select_samples.py](#select_samples)
* [ellipseselect.py](#ellipseselect)

## Summary of scripts

### `select_samples.py` script to select core subsamples
#### Requirements:
1. Python 3.6+
2. Libraries: matplotlib, pandas


#### Running on TSD Windows Desktop
The script should work right away with preinstalled Anaconda.

**(1)** Start Anaconda Prompt:
1. Open Windows Start Menu (e.g. by pressing `Win` key)
2. Start typing "anaconda ..."
3. Select *Anaconda Prompt* from the list of suggested applications.

Be prepared, Windows cmd differs from Linux terminal in many aspects (e.g. most of commands are different, autocompletion works differently, copy/paste is different).

**(2)** Navigate to the script folder:
```
> N:
> cd durable\s3-api\github\norment\moba_qc_imputation\software
```
The first command will change the drive (of note, i have `/tsd/p697/data` mounted as drive `N` on Windows, however, in your case it can be different). The second command will change directory on this drive.
Now you are in the directory with `select_samples.py` script. Try
```
> python select_samples.py --help
```

**(3)** Run the script:
```
> python select_samples.py N:\durable\projects\moba_qc_imputation\sharing\m24-ca-1kg-pca.eigenvec --out M:\p697-alexeas\test\m24.test
```
GUI should start.

**(4)** Select samples:
1. Show/hide samples using the pannel on the right. There are two lables for MoBa sample: "MoBa^" and "MoBa_". When selected, the former draws MoBa data on top of 1KG, while the latter draws MoBa behind 1KG samples.
2. If necessary zoom in/out, move and reset to the original view using buttons on top of the plot (navigation toolbar). Complete description of the navigation toolbar can be found [here](https://matplotlib.org/3.2.2/users/navigation_toolbar.html).
3. Adjust ellipse parameters (X, Y - coordinates of the ellipse center, W/H - large and small axis of the ellipse, A - angle in degrees taken from the horizontal line in the counter-clock direction).
4. Press *Draw* to draw an ellipse with given parameters. Samples within ellipse are colored with balck. Check console to see how many samples are witin selection.
5. If necessary, you can clear current ellipse by pressing *Clear*.
6. When selection is done, press *Select*. Four files are created: `OUT.selected_samples.csv` (contains FID and IID of the selected samples from MoBa), `OUT.selected_samples_1kg.csv` (contains FID and IID of the selected samples from 1KG), `OUT.selected_samples.png` (figure with selection), `OUT.selected_samples.ellipse` (selection ellipse parameters). Where `OUT` is given by the `--out` argument of the script.

**(5)** To see all available command line arguments type:
```
> python select_samples.py --help
```

#### Running on TSD Linux desktop

##### Setup of the environment before the first usage and test run

**(1)** Go to *p697-submit* and load *python3.7.3* module:
```sh
$ ssh -Y p697-submit
$ module load python3.gnu/3.7.3
```
Try:
```sh
$ python3 --version
```
This should print: `Python 3.7.3`

**(2)** Create *py37* virtual environment:
```sh
$ python3 -m venv $HOME/py37
```
This will create `$HOME/py37` folder with basic python packages.

**(3)** Activate *py37* environment:
```sh
$ source $HOME/py37/bin/activate
```
If successful, `(py37)` will be added in the beginning of your command line. When *py37* is activated, your default `python` will be from this virtual environment.
In the following instructions the case when the command is executed with activated *py37* is indicated by starting the instruction with `(py37)$` instead of `$` for the commands which do not require *py37* to be activated.
Check the output of the following commands:
```sh
(py37)$ which python
(py37)$ python --version
(py37)$ which pip
```
Should print: `~/py37/bin/python`, `Python 3.7.3` and `~/py37/bin/pip` correspondingly.

At any moment you can deactivate the *py37* environment by typing: `$ deactivate`. `(py37)` should disappear from the beginning of your command line.
To activate again, type: `$ source $HOME/py37/bin/activate`.
If you log out from TSD and then log in again, to use this python you first should load the *python3.7.3* module and then activate *py37* environment:
```sh
$ module load python3.gnu/3.7.3
$ source $HOME/py37/bin/activate
```

**(4)** Update pip and install python packages required for the script (*py37* must be activated, when you run the following command):
```sh
(py37)$ pip install --upgrade pip
(py37)$ pip install matplotlib pandas
```
Now `(py37)$ python select_samples.py --help` should work.

**(5)** Go to the folder with `select_sampels.py` script and run it (with activated *py37*):
```sh
(py37)$ python select_sampels.py /tsd/p697/data/durable/projects/moba_qc_imputation/sharing/m24-ca-1kg-pca.eigenvec --out test
```
In a few seconds GUI window should appear.
Press *Draw* button to draw the ellipse with initial X/Y/W/H/A settings (X, Y - coordinates of the ellipse center, W/H - large and small axis of the ellipse, A - angle in degrees taken from the horizontal line in the counter-clock direction).
Press *Select* to save selected samples (`test.selected_samples.csv` file with selected MoBa samples and `test.selected_samples_1kg.csv` with selected 1KG samples), plot (`test.selected_samples.png`) and ellipse parameters (`test.selected_samples.ellipse`). The prefix (`test`) of the output files can be changed by changing the `--out` argument. Check console whether there are no errors/warnings. Now you may close the GUI window.

**(6)** To see all available command line arguments type:
```
(py37)$ python select_samples.py --help
```

##### Using the script
You only need to setup the *py37* environment prior to the first use. Once you have done it, to run the script you will need the following commands:
```sh
$ ssh -Y p697-submit
$ module load python3.gnu/3.7.3
$ source $HOME/py37/bin/activate
```
The script is ready to use. 

### `ellipseselect.py`: new script to select core subsamples
The script aims to replace old `select_samples.py` script. It is similar to the old script but uses another (more suitable) library for interactive plotting making the program more responsive and easier to maintain.

#### Prepare environment
From Windows/Linux login node:
- ssh to p697-appn-norment01 (with Putty on Windows).
- On p697-appn-norment01 run following commands:
```sh
$ module load python3.gnu/3.7.3
$ python3 -m venv $HOME/ellipse
$ source $HOME/ellipse/bin/activate
$ pip install --upgrade pip
$ pip install numpy pandas bokeh matplotlib
```
This should be done only once before the first usage.
#### Run the script and select samples
- Go to the script folder and run commands:
```sh
$ module load python3.gnu/3.7.3
$ source $HOME/ellipse/bin/activate
$ bokeh serve --allow-websocket-origin=p697-appn-norment01:5006 ellipseselect.py --args PATH_TO_EIGENVEC
```
If you already loaded `python3.gnu/3.7.3` module, you don't need to run the first command.
Similarly if `ellipse` environment is already active, it's not necessary to run `activate` command again (of note, to deactivate `ellipse` environment type `deactivate`).
The third command starts web server.
Replace `PATH_TO_EIGENVEC` with the path to your .eigenvec file, for example: `/tsd/p697/data/durable/projects/moba_qc_imputation/sharing/m24-ca-1kg-pca.eigenvec`.
- Then on login node (WIndows/Linux) open Firefox browser and in the address bar type: "p697-appn-norment01:5006/ellipseselect".
You should see a webpage with two plots above and text fields and buttons below. Left plot has MoBa samples on top, right plot has 1KG samples on top.
  - Use toolbar (on the right) to zoom, drag and reset (to the original axis limits) the figure.
  - Type in "Output prefix" text field to define output prefix of saved files.
  - Modify "Title" text field to change the title of the plots.
  - Modify "Center X", "Center Y", "Width", "Height" and "Angle" text fields to define ellipse.
  - Press "Update" to change the title and/or draw the ellipse.
  - Press "Save" to save current selection. The same as previously set of files is created: `test.selected_samples.csv` file with selected MoBa samples, `test.selected_samples_1kg.csv` with selected 1KG samples, `test.selected_samples.png` figure (contains both MoBa/1KG on top figures) and `test.selected_samples.ellipse` with ellipse parameters. Saved figure is slightly different from what you see on the webpage. Most natable difference is location of the legend which is located inside the right figure in the web version, while in the saved version it is placed outside the plot area. So if legend in the web version overlays some figure details it will not be an issue in the saved version. You may take this into account when adjusting the figure.
- To stop the script (webserver):
  - Close browser tab.
  - In in terminal (where you started the webserver) press Ctrl+C.







 
