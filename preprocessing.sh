#! /bin/bash

#########################################################################################################
#
# PreProcessing pipeline and T1w/FLAIR-ratio calculation
#
# Adapted from Cappelle et al. (Cappelle S et al. T1w/FLAIR ratio standardization as a myelin marker in MS patients. Neuroimage Clin. 2022;36:103248. doi: 10.1016/j.nicl.2022.103248)
# Original script: https://github.com/treanus/KUL_NIS/blob/master/docs/KUL_T1T2FLAIRMTR_ratio/KUL_T1T2FLAIRMTR_ratio.md
#
# Description : This script requires MRTrix3, samseg, hd-bet and N4BiasFieldCorrection
# Inputs : This script needs a t1w.nii and flair.nii image
# Outputs : Preprocessed images (t1w_iso_biascorrected_calib.nii and flair_iso_biascorrected_calib_reg2T1w.nii) and T1w/FLAIR-ratio (T1FLAIR-ratio.nii)
#
#########################################################################################################

# Regrid to isotropic voxel-size (1mm3)
mrgrid t1w.nii regrid -voxel 1 t1w_iso.nii -force
mrgrid flair.nii regrid -voxel 1 flair_iso.nii -force

# Biasfield correction for T1w image
N4BiasFieldCorrection -d 3 \
        -i t1w_iso.nii \
        -o t1w_iso_biascorrected.nii

# Biasfield correction for FLAIR image
N4BiasFieldCorrection -d 3 \
        -i flair_iso.nii \
        -o flair_iso_biascorrected.nii

# Register FLAIR to T1w
flirt -in flair_iso_biascorrected.nii -ref t1w_iso_biascorrected.nii -out flair_iso_biascorrected_reg2T1w.nii -usesqform -applyxfm
flirt -in flair_iso_biascorrected_reg2T1w.nii -ref t1w_iso_biascorrected.nii -out flair_iso_biascorrected_reg2T1w.nii

# Run Samseg for WMH segmentation
run_samseg --input flair_iso_biascorrected_reg2T1w.nii 1w_iso_biascorrected.nii --lesion --lesion-mask-pattern 1 0  --threshold 0.3 --output ./ --threads 6 
mri_convert seg.mgz seg.nii

# Run HD-bet for brain mask segmentation
hd-bet -i t1w_iso_biascorrected.nii.gz -o t1w_iso_biascorrected_brain.nii.gz
mri_convert t1w_iso_biascorrected_brain_mask.nii.gz t1w_iso_biascorrected_brain_mask.nii

mri_binarize --i seg.nii --match 99 --o mask_wmh.nii

# Exclude WMH from the brain mask
fslmaths t1w_iso_biascorrected_brain_mask.nii -sub mask_wmh.nii t1w_iso_biascorrected_brain_mask_nowmh.nii

mask=t1w_iso_biascorrected_brain_mask_nowmh.nii
template_T1w=tpl-MNI152NLin2009aSym_res-1_Cappelle2021_T1w.nii
template_FLAIR=tpl-MNI152NLin2009aSym_res-1_Cappelle2021_FLAIR.nii
template_mask=tpl-MNI152NLin2009aSym_res-1_Cappelle2021_T1w_mask_brain_mask.nii

# Histogram intensity normalization of the T1w image
mrhistmatch \
	-mask_input $mask \
	-mask_target $template_mask \
	nonlinear \
	t1w_iso_biascorrected.nii  \
	$template_T1w \
	t1w_iso_biascorrected_calib.nii -nthreads 12 -force

# Histogram intensity normalization of the FLAIR image
mrhistmatch \
	-mask_input $mask \
	-mask_target $template_mask \
	nonlinear \
	flair_iso_biascorrected_reg2T1w.nii \
	$template_FLAIR \
	flair_iso_biascorrected_calib_reg2T1w.nii -nthreads 12 -force
  
# Use the normalized images to calculate the T1w/FLAIR-ratio  
mrcalc \
	t1w_iso_biascorrected_calib.nii \
	flair_iso_biascorrected_calib_reg2T1w.nii -divide \
	t1w_iso_biascorrected_brain_mask.nii -multiply \
	T1FLAIR-ratio.nii -nthreads 12 -force	

