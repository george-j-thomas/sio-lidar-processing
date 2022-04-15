function [] = ccd_airborne_processing(source,survey)

    survey_merged = [survey, '_Merged'];

    dir_nowaves = ['\\reefbreak\group\LiDAR\',source,'\LiDAR_Processed_Level1\**\*NoWaves*.las'];
    dir_processedL2 = ['\\reefbreak\group\LiDAR\',source,'\LiDAR_Processed_Level2\'];
    dir_org = ['\\reefbreak\group\LiDAR\',source,'\to_organize\'];
    dir_surv = ['\\reefbreak\group\LiDAR\',source,'\to_organize\',survey];
    dir_merge = ['\\reefbreak\group\LiDAR\',source,'\to_organize\',survey_merged];
    dir_proc = 'D:\LidarProcessing_Level2';
    dir_poly = [dir_proc,'\MOP_Polygons\CCD_Polys'];

    lbase = 'C:\LAStools\bin\';

    %%% LASTOOLS PATH
    lpath{1} = [lbase,'las2las.exe'];
    lpath{2} = [lbase,'lasclip.exe'];
    lpath{3} = [lbase,'lasmerge.exe'];
    lpath{4} = [lbase,'lasgrid.exe'];

    cd(dir_surv)

    % Polygon / Area lists
    bigtiles = [dir_poly, '\CA_MOP_bigtiles.shp'];
    area_tiles = {'\SanClemente_mops.shp','\Huntington_mops.shp','\MalibuLagoon_mops.shp','\LighthouseField_mops.shp'};
    areas = {'\SanClemente','\Huntington','\MalibuLagoon','\LighthouseField'};

    % Clean all tiles w las2las, edit input crs as needed
    cleaned_fol = [dir_surv,'\cleaned'];
    system([lpath{1}, ' -lof lof_ca.txt -keep_class 2 10 -nad83_2011 -longlat -vertical_navd88 -target_utm 11N  -olaz -odir ',cleaned_fol]) 

    % Split clean tiles into desired areas for CCD
    for k = 1:length(area_tiles)

        poly = [dir_poly,area_tiles{k}];
        outfol = [dir_surv,areas{k}];
        if exist(outfol)~=7
            mkdir(outfol)
        end

        system([lpath{2}, ' -i "',cleaned_fol,'\*.laz','" -poly ',poly,' -split -olaz -odir ',outfol])
    end

    for k = 1:length(areas)

        infol = [dir_surv,areas{k}];
        outbeach = [infol,'\beach'];
        if exist(outbeach)~=7
            mkdir(outbeach)
        end

        %%% Create directory from area folder
        listing=dir(infol);
        listing(1:2)=[];

        %%% Read txt files with beach & cliff tile numbers
        bnum=dlmread([dir_poly,area_tiles{k}(1:end-4),'_beach.txt']);

        %%% Sort Beach and Cliff ground tiles by number
        for ccc=1:length(listing)
            [~,bb,cc]=fileparts(listing(ccc).name);
            %%% Only operate on .laz files
            if(strcmp(cc,'.laz'))
                num=str2num(bb(end-5:end));
                %%% Sort Beach Tiles to beach_ground folder
                for ddd=1:length(bnum) 
                    if(bnum(ddd)==num) 
                        copyfile([listing(ccc).folder,'\',listing(ccc).name],outbeach); 
                    end
                end
            end
        end

        % Merge tiles frome each area
        outname = [listing(1).name(1:9),areas{k}(2:end),'.laz'];
        system([lpath{3}, ' -i "',outbeach,'\*.laz','" -olaz -o ',outname,' -odir ',dir_merge])

    end

    % Create DEMs for each area
    system([lpath{4},' -i "',dir_merge,'\*.laz"', ' -step 1 -meter -average -elevation -otif -nad83 -utm 11north -vertical_navd88"']);

end

