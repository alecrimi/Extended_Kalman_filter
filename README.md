This folder contains the source code for Star-Kalman tracking for vessel in Ultrasoun as described in:

@inproceedings{crimi2014vessel,
  title={Vessel tracking for ultrasound-based venous pressure measurement},
  author={Crimi, Alessandro and Makhinya, Maxim and Baumann, Ulrich and Sz{\'e}kely, G{\'a}bor and Goksel, Orcun},
  booktitle={2014 IEEE 11th International Symposium on Biomedical Imaging (ISBI)},
  pages={306--309},
  year={2014},
  organization={IEEE}
}

Version 0.1

-------------------------------------
The scripts assume there is available a video ultrasound streaming, a pressure streaming, and a manual annotation of the vessel giving the ground truth. 
Respectively those are given in a VPR files ( pressure streaming) and SXI for the ultrasound streaming or manual annotations.

Example of use: 
assuming we have two files as test.vpr and test.sxi
test_star_kalman('test');
This is the semi-automatic version of the algorithm, therefore remember to initialize the tracking as shown in the picture initialization.png ![alt tag](https://github.com/alecrimi/Extended_Kalman_filter/blob/master/initialization.png)
To run this example you need to download the ultrasound streaming (test.sxi) from https://www.dropbox.com/s/0j63ixt7hxkgltk/test.sxi?dl=0 
For the full complete version, with the automatic initialization step, please refer to the C++ implementation.

The test_star_kalman.m script iterates through the whole streaming given in those files. This is a public function which calls the main algorithm which is 
performed frame by frame.
There are also two wrap functions to run over the entire dataset acquired at USZ: global_script.m and star_kalman_wrap.m

There are two subfolders:
- main_alg, which contains the core algorithm star_kalman.m and supporting script of it.

- lib, which contains other scripts used to add affine-flow compensation and to read other format of ultrasound streaming:
  affine_flow.m of David Young
  dftregistration.m of Ann M. Kowalczyk
  uread.m of Paul Otto


All code is given freely as GNU/General Public License v. 3.0
https://www.gnu.org/licenses/gpl-3.0.html
