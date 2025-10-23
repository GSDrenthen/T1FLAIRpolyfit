function [polyfit] = train_polyfit(subjects)

    % Training a second order polynomial surface fitting method for a
    % better combination of T1- and FLAIR-weighted contrasts for the
    % purpose of myelin-imaging

    T1Wtot = []; FLRtot = [];  MWFtot = [];
    
    for nn = 1:length(subjects)

        % Load relevant nifti's of the subjects
        % Note that all images need to be coregistered to the MWF and that
        % the FLAIR and T1w images should be pre-processed for
        % T1/FLAIR-ratio analysis (Capelle et al: 10.1016/j.nicl.2022.103248)
        
        msknii = load_untouch_nii(['path/' subjects{nn} '/seg.nii']);
        mwfnii = load_untouch_nii(['path/' subjects{nn} '/MWF.nii']);
        flair = load_untouch_nii(['path/' subjects{nn} '/FLAIR.nii']);
        t1 = load_untouch_nii(['path/' subjects{nn} '/T1w.nii']);   

        msk = double(msknii.img<100 & msknii.img>0);
    
        T1W = double(t1.img);
        FLR = double(flair.img);
        MWF = double(mwfnii.img);
    
        T1Wtot = [T1Wtot; (T1W(msk==1))];
        MWFtot = [MWFtot; (MWF(msk==1))];
        FLRtot = [FLRtot; (FLR(msk==1))];
    
    end

    MWFtot(isnan(MWFtot)) = 0;
    polyfit = fit([T1Wtot,FLRtot],MWFtot*100,'poly22','Normalize','on','Weights',100.*(-1.*raylpdf(MWFtot*10) + 1),'Robust','LAR');

end