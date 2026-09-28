def polyfit22(t1w, flr, seg):
    # MATLAB normalisatie
    import nibabel as nib
    import numpy as np

    t1 = nib.load(t1w).get_fdata()
    flair = nib.load(flr).get_fdata()
    samseg = nib.load(seg).get_fdata()

    xn = (t1 - 35750.0) / 13150.0
    yn = (flair - 30400.0) / 6884.0

    # coefficients
    p00 = 7.273
    p10 = 4.386
    p01 = -7.592
    p20 = -1.025
    p11 = -1.560
    p02 = 2.871

    z = (
        p00
        + p10 * xn
        + p01 * yn
        + p20 * xn**2
        + p11 * xn * yn
        + p02 * yn**2
    )
    wm = (samseg == 2) | (samseg == 41) | (samseg == 99)

    wm_values = z[wm]
    wm_mean = np.mean(wm_values)

    return wm_mean