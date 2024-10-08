#!/bin/bash

# ------------------------------------------------------------------------------
# Script name:  get_tck_into_standard.sh
#
# Description:  takes tck files from mrtrix, converts them to nifti and puts them in standard space #
# Author:       Hanna Willis, 06/09/24 

# ------------------------ SET UP ------------------------
all_subj='R001 R002 R003 R004 R005 R006 R007 R008 R009 R010 R011 R012 R013 R014 R015 R017 R018 R019 R020 R022 R023 R024'

# Make a new directory to store all the tracts for each sub

for subj in $all_subj
do 
# SET UP SUBJ DIRECTORY
echo "starting..." $subj

# WILL NEED TO CHANGE THESE BASED ON YOUR DATA 
PROJECT_DIR=/Volumes/Hanna_Rehab_Data/Lesion_paper/data/VSLM/diffusion_tracts
SUBJ_DIR=$PROJECT_DIR/sub-${subj}.ses-baseline
STAND=/Users/hwillis_admin/fsl/data/standard

cd $SUBJ_DIR

# Rename folders
## this is needed because all the folders downloaded from Brainlife have slightly different names for each subj which breaks the later part of the script
## also the names are annoyingly long 
mv *anat* anat
mv *dwi* dwi
mv *track* tract

# SET OTHER DIRECTORIES 
DWI=$SUBJ_DIR/dwi
TRACT=$SUBJ_DIR/tract

# ------------------------ PREPARE TRACT AND DIFF DATA ------------------------

# Convert tck into nifti (using mrtrix so you'll need this downloaded)
echo "converting tck..." $subj
tckmap -template $DWI/dwi.nii.gz $TRACT/track.tck $TRACT/tract.nii.gz

# Reorient all data to standard
fslreorient2std $DWI/dwi.nii.gz $DWI/dwi.nii.gz
fslreorient2std $TRACT/tract.nii.gz $TRACT/tract.nii.gz

# Average across the DWI volumes (makes it one volume rather than many - necessary for registration)
echo "averaging diffusion..." $subj
fslmaths $DWI/dwi.nii.gz -Tmean $DWI/dwi_av.nii.gz

# ------------------------ REGISTER TRACT TO STANDARD SPACE ------------------------

# Calculate warp for averaged diffusion to MNI space 
echo "calculate warps..." $subj
flirt -in $DWI/dwi_av.nii.gz -ref $STAND/MNI152_T1_1mm.nii.gz -omat $TRACT/dwi2mni.mat
fnirt --ref=$STAND/MNI152_T1_1mm.nii.gz --in=$DWI/dwi_av.nii.gz --aff=$TRACT/dwi2mni.mat --cout=$TRACT/warpxfm_dwi2mni.nii.gz

# Apply warp to tract
echo "applying warp to tract..." $subj
applywarp -i $TRACT/tract.nii.gz -r $STAND/MNI152_T1_1mm.nii.gz -w $TRACT/warpxfm_dwi2mni.nii.gz -o $TRACT/tract_std.nii.gz

# Add subject name to the tract file
mv tract_std.nii.gz ${subj}_tract_std.nii.gz
mv tract_std.nii.gz ${subj}_tract_std.nii.gz

# Copy this into a new directory (will need to make this if it doesn't exist)
cp -r ${subj}_tract_std.nii.gz $PROJECT_DIR/all_tracts/both_hemi

done 

## ------------------------ AVERAGE TRACTS ------------------------

# FLIP SCANS
## Flip subjects with left hemisphere lesions (so lesions are all in the right hemisphere)
## R005 R006 R011 R012 R013 R018 R019 R022 R023 R024 
## RH; 	RH;  RH;  RH;  LH;  LH;  RH;  LH;  LH;  RH
fslswapdim R013_tract_std.nii.gz -x y z R013_tract_std_flip.nii.gz
fslswapdim R018_tract_std.nii.gz -x y z R018_tract_std_flip.nii.gz
fslswapdim R022_tract_std.nii.gz -x y z R022_tract_std_flip.nii.gz
fslswapdim R023_tract_std.nii.gz -x y z R023_tract_std_flip.nii.gz

# ADD ALL SCAN TOGETHER
## Add all the tracts together in standard space using fslmaths (need fsl for this)
cd $PROJECT_DIR/all_tracts/both_hemi
fslmaths R005_tract_std.nii.gz \
-add R006_tract_std.nii.gz \
-add R011_tract_std.nii.gz \
-add R012_tract_std.nii.gz \
-add R013_tract_std*.nii.gz \
-add R018_tract_std*.nii.gz \
-add R019_tract_std.nii.gz \
-add R022_tract_std*.nii.gz \
-add R023_tract_std*.nii.gz \
-add R024_tract_std.nii.gz \
LGN_hMT_prob_mask.nii.gz

# SPLIT INTO TWO HEMISPHERES 
## sighted and blind (all overlapping now because of the flipping)
## You'll need to check scan dimensions to accurately cut the scan in half - you can do this using fslinfo $TRACT/tract_std.nii.gz
fslroi LGN_hMT_prob_mask.nii.gz LGN_hMT_prob_mask_blind.nii.gz 0 91 0 -1 0 -1
fslroi LGN_hMT_prob_mask.nii.gz LGN_hMT_prob_mask_sight.nii.gz 91 -1 0 -1 0 -1

# Flip the prob mask (so it can match the VSLM)
## You can't flip a fslroi clipped image because the image is half the size now, so this needs to be done before. 
# fslswapdim LGN_hMT_prob_mask.nii.gz -x y z LGN_hMT_prob_mask_flip.nii.gz

# # Run it again on the flipped data
# fslroi LGN_hMT_prob_mask_flip.nii.gz LGN_hMT_prob_mask_sight.nii.gz 0 91 0 -1 0 -1
# fslroi LGN_hMT_prob_mask_flip.nii.gz LGN_hMT_prob_mask_blind.nii.gz 91 -1 0 -1 0 -1






