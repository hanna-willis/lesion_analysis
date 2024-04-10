#!/bin/bash

# ------------------------------------------------------------------------------
# Script name:  visual_area_thresholds.sh
#
# Description:  takes the different visual areas, thresholds them and calculates the size #
# Author:       Hanna Willis, 10/04/24 

# ------------------------ SET UP ------------------------

# SET UP VARIABLES
# ---------------------
all_subj='PAT_R019 PAT_R020 PAT_R022 PAT_R023 PAT_R024 PAT_R006 PAT_R007 PAT_R009 PAT_R011 PAT_R013 PAT_R014 PAT_R017 PAT_R018 PAT_003 PAT_004 PAT_012 PAT_015 PAT_017 PAT_019 PAT_020 PAT_021 PAT_022 PAT_S202 PAT_S203 PAT_S204 PAT_S205 PAT_S206 PAT_S208 PAT_S209 PAT_S210 PAT_S211 PAT_S214 PAT_S215 PAT_S216 PAT_S217 PAT_S218 PAT_S220 PAT_S401 PAT_S219'
all_areas='V1 V4 V5'
all_thresholds='10 30 50'

# SET UP PATHS
# ---------------------
SCRIPT_LOC=/Users/hwillis_admin/Desktop/OneDrive*Nexus365/Hemianopia_Rehab_Data/Patients/Scripts/rehab/analysis/mri_analysis/lesion/
DATA_LOC=/Volumes/Hanna_Rehab_Data/Lesion_paper

# MAKE DATAFILE
# ---------------------
cd $DATA_LOC
echo 'Subj, Hemisphere, Visual_Area, Mask_Threshold, Lesion_Size, Visual_Area_Size, Overlap_Size' > visual_area_size_cal.csv


# ------------------------ THRESHOLD MASKS OF INTEREST ------------------------

# # Create visual masks in standard space at different thresholds
# for roi in V1 V4 V5
# do
# for hemisphere in L R
# do
# # Threshold masks by 10,30 and 50%
# fslmaths ${roi}_${hemisphere}.nii.gz -thr 10 ${roi}_${hemisphere}_thr10.nii.gz
# fslmaths ${roi}_${hemisphere}.nii.gz -thr 30 ${roi}_${hemisphere}_thr30.nii.gz
# fslmaths ${roi}_${hemisphere}.nii.gz -thr 50 ${roi}_${hemisphere}_thr50.nii.gz

# # View these to make sure they look sensible 
# fsleyes /Users/hwillis_admin/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz \
# ${roi}_${hemisphere}_thr10.nii.gz -cm red \
# ${roi}_${hemisphere}_thr30.nii.gz -cm blue \
# ${roi}_${hemisphere}_thr50.nii.gz -cm green 
# done
# done

# ------------------------ THRESHOLD LESIONS ------------------------

# Remake the lesion masks for each person - takes the overlap of 2 people
# for subj in $all_subj
# do
# fslmaths ${subj}_*mask_sum.nii.gz -thr 1.9 ${subj}_mask_cons.nii.gz
# fslmaths ${subj}_mask_cons.nii.gz -bin ${subj}_mask_cons.nii.gz
# echo $subj mask thresholded
# done 

# ------------------------ MOVE MASKS INTO ANATOMICAL SPACE ------------------------

# Move the masks into structural space
# ---------------------

for subj in $all_subj
do 
	echo "starting" $subj
	ANAT=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/anat
	STAND=/Users/hwillis_admin/fsl/data/standard
	WARP=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/${subj}
	MASK=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/orig_masks
	LESION=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/lesions

# Create the folder if it doesn't exist
if [ ! -d "$WARP" ]; then
    mkdir -p "$directory"
    echo "Directory created: $directory"
else
    echo "Directory already exists: $directory"
fi

# Create struct-standard warp files
# ---------------------

	echo "creating warp files"
flirt -in $ANAT/${subj}.nii.gz -ref $STAND/MNI152_T1_1mm.nii.gz -omat $WARP/struct2mni.mat
fnirt --ref=$STAND/MNI152_T1_1mm.nii.gz --in=$ANAT/${subj}.nii.gz --aff=$WARP/struct2mni.mat --cout=$WARP/warpxfm_struct2mni.nii.gz
invwarp -w $WARP/warpxfm_struct2mni.nii.gz -o $WARP/warpxfm_mni2struct.nii.gz -r $ANAT/${subj}.nii.gz

# Loop through each hemisphere, visual area and threshold 

  for hemisphere in L R
  do 
    for visual_area in $all_areas
    do
      for threshold in $all_thresholds
      do

Move visual masks into structural space 
echo "applying warp files to visual areas"
applywarp -i $MASK/${visual_area}_${hemisphere}_thr${threshold}.nii.gz -r $ANAT/${subj}.nii.gz -w $WARP/warpxfm_mni2struct.nii.gz -o $WARP/${subj}_${visual_area}_${hemisphere}_thr${threshold}
fslmaths $WARP/${subj}_${visual_area}_${hemisphere}_thr${threshold} -bin $WARP/${subj}_${visual_area}_${hemisphere}_thr${threshold}
echo "done" $hemisphere $visual_area $threshold


# Take overlap between lesion and visual area 
# ---------------------

echo "calculate overlap" $subj
fslmaths $WARP/${subj}_${visual_area}_${hemisphere}_thr${threshold}.nii.gz -mas $LESION/${subj}_lesion.nii.gz $WARP/${subj}_lesion_in_${hemisphere}_${visual_area}_thr${threshold}.nii.gz

done
done
done
done

# ------------------------ VISUALLY INSPECT MASKS IN ANATOMICAL SPACE ------------------------
# Flip lesions
# for subj in PAT_003 PAT_004 PAT_012 PAT_020 PAT_022 PAT_S204 PAT_S206 PAT_S208 PAT_S211 PAT_S218
# do 
# 	echo "starting" $subj
# # Loop through each hemisphere, visual area and threshold 
# WARP=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/${subj}
# ANAT=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/anat
# LESION=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/lesions

# cp $LESION/${subj}_lesion.nii.gz flip
# fslswapdim $LESION/${subj}_lesion.nii.gz -x y z $LESION/${subj}_lesion.nii.gz

# done

# Check lesions
# ---------------------
for subj in $all_subj
do 
	echo "starting" $subj
	# Loop through each hemisphere, visual area and threshold 
	WARP=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/${subj}
	ANAT=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/anat
	LESION=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/lesions

	fsleyes $ANAT/${subj}.nii.gz \
	$LESION/${subj}_lesion.nii.gz
done

# Check visual areas 
# ---------------------

for subj in $all_subj
do 
	echo "starting" $subj
# Loop through each hemisphere, visual area and threshold 
	WARP=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/${subj}
	ANAT=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/anat

# Check V1
	fsleyes $ANAT/${subj}.nii.gz \
	$WARP/${subj}_V1_L_thr10 -cm red \
	$WARP/${subj}_V1_L_thr30 -cm blue \
	$WARP/${subj}_V1_L_thr50 -cm green \
	$WARP/${subj}_V1_R_thr10 -cm red \
	$WARP/${subj}_V1_R_thr30 -cm blue \
	$WARP/${subj}_V1_R_thr50 -cm green \
	$WARP/${subj}_lesion_in_L_V1_thr10 -cm white \
	$WARP/${subj}_lesion_in_L_V1_thr30 -cm white \
	$WARP/${subj}_lesion_in_L_V1_thr50 -cm white \
	$WARP/${subj}_lesion_in_R_V1_thr10 -cm white \
	$WARP/${subj}_lesion_in_R_V1_thr30 -cm white \
	$WARP/${subj}_lesion_in_R_V1_thr50 -cm white

# Check V4
fsleyes $ANAT/${subj}.nii.gz \
$WARP/${subj}_V4_L_thr10 -cm red \
$WARP/${subj}_V4_L_thr30 -cm blue \
$WARP/${subj}_V4_L_thr50 -cm green \
$WARP/${subj}_V4_R_thr10 -cm red \
$WARP/${subj}_V4_R_thr30 -cm blue \
$WARP/${subj}_V4_R_thr50 -cm green \
$WARP/${subj}_lesion_in_L_V4_thr10 -cm white \
$WARP/${subj}_lesion_in_L_V4_thr30 -cm white \
$WARP/${subj}_lesion_in_L_V4_thr50 -cm white \
$WARP/${subj}_lesion_in_R_V4_thr10 -cm white \
$WARP/${subj}_lesion_in_R_V4_thr30 -cm white \
$WARP/${subj}_lesion_in_R_V4_thr50 -cm white

# Check V5
fsleyes $ANAT/${subj}.nii.gz \
$WARP/${subj}_V5_L_thr10 -cm red \
$WARP/${subj}_V5_L_thr30 -cm blue \
$WARP/${subj}_V5_L_thr50 -cm green \
$WARP/${subj}_V5_R_thr10 -cm red \
$WARP/${subj}_V5_R_thr30 -cm blue \
$WARP/${subj}_V5_R_thr50 -cm green \
$WARP/${subj}_lesion_in_L_V5_thr10 -cm white \
$WARP/${subj}_lesion_in_L_V5_thr30 -cm white \
$WARP/${subj}_lesion_in_L_V5_thr50 -cm white \
$WARP/${subj}_lesion_in_R_V5_thr10 -cm white \
$WARP/${subj}_lesion_in_R_V5_thr30 -cm white \
$WARP/${subj}_lesion_in_R_V5_thr50 -cm white

done 

# ------------------------ CALCULATE PROPORTIONS ------------------------

for subj in $all_subj
do 
	echo "calculating sizes"
	echo "starting" $subj
	ANAT=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/anat
	STAND=/Users/hwillis_admin/fsl/data/standard
	WARP=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/${subj}
	MASK=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/orig_masks
	LESION=/Volumes/Hanna_Rehab_Data/Lesion_paper/Lesion_masks/lesions

# Loop through each hemisphere, visual area and threshold 

  for hemisphere in L R
  do 
    for visual_area in $all_areas
    do
      for threshold in $all_thresholds
      do

echo 'running' $subj $hemisphere $visual_area $threshold

# Calculate lesion size
# ---------------------

lesion_size=`fslstats $LESION/${subj}_lesion.nii.gz -V` 
lesion_size_2=`echo "$lesion_size" | awk '{print $2}'`

# Calculate visual area size
# --------------------------

area_size=`fslstats $WARP/${subj}_${visual_area}_${hemisphere}_thr${threshold} -V`
area_size_2=`echo "$area_size" | awk '{print $2}'`

# Calculate overlap size 
# ----------------------

overlap_size=`fslstats $WARP/${subj}_lesion_in_${hemisphere}_${visual_area}_thr${threshold}.nii.gz -V`
overlap_size_2=`echo "$overlap_size" | awk '{print $2}'`

echo "saying data"
echo $subj,$hemisphere, $visual_area, $threshold, $lesion_size_2,$area_size_2,$overlap_size_2 >> $DATA_LOC/visual_area_size_cal.csv

done 
done
done
done

# ------------------------ MAKE PROBABILISTIC MAP ------------------------
# Only make this for the participants that don't show residual vision, and have no damage to MT.

# Move lesions into standard space 
# --------------------------------

for subj in PAT_015 PAT_017 PAT_020 PAT_S208 PAT_R022 
do
	echo 'running' $subj
WARP=/Volumes/Hanna_Rehab_Data/Lesion_paper/visual_masks/${subj}
applywarp -i $LESION/${subj}_lesion.nii.gz -r $STAND/MNI152_T1_1mm.nii.gz -w $WARP/warpxfm_struct2mni.nii.gz -o $LESION/${subj}_lesion_std.nii.gz
done 

# Check warps
# # ---------


fsleyes $STAND/MNI152_T1_1mm.nii.gz \
PAT_015_lesion_std.nii.gz \
PAT_017_lesion_std.nii.gz \
PAT_020_lesion_std.nii.gz \
PAT_S208_lesion_std.nii.gz \
PAT_R022_lesion_std.nii.gz 

# Add lesions together 
# --------------------

cd $LESION
fslmaths PAT_015_lesion_std.nii.gz \
-add PAT_017_lesion_std.nii.gz \
-add PAT_020_lesion_std.nii.gz \
-add PAT_S208_lesion_std.nii.gz \
-add PAT_R022_lesion_std.nii.gz \
prob_mask.nii.gz

# View colourmap
# --------------

fsleyes $STAND/MNI152_T1_1mm.nii.gz \
prob_mask.nii.gz













