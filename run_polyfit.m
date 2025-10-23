function [mwf_wm,t1flr_wm,t1flrpoly_wm] = run_polyfit(polyfit,subjects,LOO)

    % Applying a second order polynomial surface fit on dataset with or
    % without a leave-one-out strategy

    for nn = 1:length(subjects)
        if LOO > 0
            subjects_loo = subjects;
            subjects_loo(nn) = [];
            [polyfit_loo] = train_polyfit(subjects_loo);
        end

        % Load relevant nifti's of the subjects
        % Note that all images need to be coregistered to the MWF and that
        % the FLAIR and T1w images should be pre-processed for
        % T1/FLAIR-ratio analysis (Capelle et al: 10.1016/j.nicl.2022.103248)
        
        msknii = load_untouch_nii(['path/' subjects{nn} '/seg.nii']);
        mwfnii = load_untouch_nii(['path/' subjects{nn} '/MWF.nii']);
        flair = load_untouch_nii(['path/' subjects{nn} '/FLAIR.nii']);
        t1 = load_untouch_nii(['path/' subjects{nn} '/T1w.nii']);
        
        wm = (msknii.img==2 | msknii.img==41 | msknii.img==99);
       
        t1flr = (double(t1.img).^1 .* double(flair.img).^-1);
    
        if LOO > 0
            T1FLpoly = (polyfit_loo(double(t1.img),(double(flair.img))));
        else
            T1FLpoly = (polyfit(double(t1.img),(double(flair.img))));
        end
    
        mwf = mwfnii.img;
        t1flr_wm(nn) = mean(t1flr(wm));
        t1flrpoly_wm(nn) = mean(T1FLpoly(wm));
        mwf_wm(nn) = mean(mwf(wm));
    end
end