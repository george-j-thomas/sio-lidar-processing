function [newfoldername] = ExecuteLastoolsRoutine(filename, polyStyle)


% bpath = 'Y:\LiDAR\LidarProcessing\LidarProcessing_Level2';
bpath = 'D:\LidarProcessing_Level2';
dpath = 'D:\LidarProcessing_Level2';
lbase = 'C:\LAStools\bin\';

%%% ADD NECESSARY FUNCTIONS PATH
addpath([dpath,'\functions'])

%%% LASTOOLS PATHS
lasclip = [lbase,'lasclip.exe'];
lasinfo = [lbase,'lasinfo.exe'];
las2las = [lbase,'las2las.exe'];
lasmerge = [lbase,'lasmerge.exe'];
lasgrid = [lbase,'lasgrid.exe'];

%%% MAIN PROCESSING FOLDERS
input_fol = '0_Input_Files';
inter_fol = '1_Intermediate_Files';
final_fol = '2_Final_Output_Files';

%%% SUB PROCESSING FOLDERS
dname{1}='lasclip_out';
dname{2}='processing_directory';
dname{3}='reclip_reclass';
dname{4}='lasclip_ground';
dname{5}='lasclip_nonground';
dname{6}='Beach_And_Backshore';
dname{7}='Beach_Only';
dname{8}='Tiles';
dname{9}='Ground';
dname{10}='Nonground';


%%% GROUND FILTER PATH

% OLD RAMBO
% gpath{1}=[dpath,'\Olsen_Ground_Filter\TriRAI_20181031\Las_Reader_BPD_20181031.exe'];
% gpath{2}=[dpath,'\Olsen_Ground_Filter\TriRAI_20181031\TriRAI_20181031.exe'];

% NEW RAMBO
gpath{1}=[bpath,'\20220119_RamboGui_V1p1j\20210304_RamboGui_V1p1i\RamboEngine_X64\Las_Reader_BPD_20200715.exe'];
gpath{2}=[bpath,'\20220119_RamboGui_V1p1j\20210304_RamboGui_V1p1i\RamboEngine_X64\RamboEngine_X64_20200715.exe'];

%%% SET DESIRED POLYGON PATH
if strcmpi(polyStyle, 'mops') == 1
    % MOP SHAPEFILE PATH
    spath{1}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\SD_ManualBackbeach_polys_buffer.shp'];
    spath{2}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\SD_ManualBackbeach_polys.shp'];
    spath{3}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\SD_ManualBackbeach_table.txt'];
elseif strcmpi(polyStyle, 'malibu') == 1
    % MALIBU SHAPEFILE PATH
    spath{1}=[bpath,'\MOP_Polygons\Malibu\CA_Backbeach_MOP_poly_buffer.shp'];
    spath{2}=[bpath,'\MOP_Polygons\Malibu\CA_Backbeach_MOP_poly.shp'];
    spath{3}=[bpath,'\MOP_Polygons\Malibu\CA_Backbeach_MOP_table.txt'];
elseif strcmpi(polyStyle, 'willrogers') == 1
    % WILL ROGERS SHAPEFILE PATH
    spath{1}=[bpath,'\MOP_Polygons\WillRogers\20210324_WillRogers_poly_buffer.shp'];
    spath{2}=[bpath,'\MOP_Polygons\WillRogers\20210324_WillRogers_poly.shp'];
    spath{3}=[bpath,'\MOP_Polygons\WillRogers\20210324_WillRogers_table.txt'];
elseif strcmpi(polyStyle, 'pendleton') == 1
    % Pendleton SHAPEFILE PATH
    spath{1}=[bpath,'\MOP_Polygons\Pendleton\Pendleton_mops_buffer.shp'];
    spath{2}=[bpath,'\MOP_Polygons\Pendleton\Pendleton_mops.shp'];
    spath{3}=[bpath,'\MOP_Polygons\Pendleton\Pendleton_mops_table.txt'];    
else
    disp('Not a valid polygon style, must be "poly3", "mops", or a beach-specific style')
end

    %%%
    %%% LASCLIP INTO BUFFERED POLYGONS
    %%%
        disp(['lasclip into buffered polys ...  ',filename])
        % Set Output to lasclip_out
        outdir = [bpath,'\',inter_fol,'\',dname{1}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        % Lasclip into buffered polygons
        system([lasclip,' -i "',bpath,'\',input_fol,'\',filename,'"',...
        ' -drop_class 7 9 18 -poly ',spath{1},' -split',...
        ' -odir "',outdir,'"']);
    %%%
    %%% LAS INFO, REMOVE IF POINT NUMBER < 100
    %%% get info from each file - spit to txt file - check if pnum<10
    
        disp(['lasinfo ...  ',filename])
        % Create directory from lasclip_out
        listing3=dir(outdir);
        listing3(1:2)=[];
        % Las Info - Spit to .txt
        system([lasinfo,' -i "',bpath,'\',inter_fol,'\',dname{1},'\*.las','" -otxt']);
        % Re-Create directory from lasclip_out
        listing3=dir(outdir);
        listing3(1:2)=[];
        % Find Number of Points in file
        for ccc=1:length(listing3)
            [~,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.txt'))
                fid = fopen([outdir,'\',listing3(ccc).name]);
                dummy = textscan(fid,'%s','delimiter','\n');
                TextAsCells = dummy{1,1};
                fclose(fid);
                
                % Extract las version number from lasinfo report
                v_mask = ~cellfun(@isempty, strfind(TextAsCells, 'version major.minor'));
                v_line = TextAsCells(v_mask);
                veee = cell2mat(v_line);
                lnum=findstr(veee,':');
                vnum=str2num(veee(lnum+1:end));
                
                % Find number of points depending on las version
                if vnum == 1.4
                    % Extract point count from lasinfo report
                    mask = ~cellfun(@isempty, strfind(TextAsCells, 'extended number of point records'));
                    p_line = TextAsCells(mask);
                    eee = cell2mat(p_line);
                    lnum=findstr(eee,':');
                    pnum=str2num(eee(lnum+1:end));
                else
                    % Extract point count from lasinfo report
                    mask = ~cellfun(@isempty, strfind(TextAsCells, 'number of point records'));
                    p_line = TextAsCells(mask);
                    eee = cell2mat(p_line(1));
                    lnum=findstr(eee,':');
                    pnum=str2num(eee(lnum+1:end));
                end
                
                % Delete lasinfo .txt file
                delete([outdir,'\',listing3(ccc).name]);

                % Delete .las tile if pnum<10
                if( pnum<10)%~contains(filename, 'miniRanger')) 
                    delete([outdir,'\',bb,'.las']); 
                    disp(['Deleting ',bb])
                end
            end
        end
    %%%
    %%% LAS2LAS CONVERT TO LAS1.2
    %%%
        disp(['las2las ...  ',filename])
        outdir = [bpath,'\',inter_fol,'\',dname{2}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        system([las2las,' -i "',bpath,'\',inter_fol,'\',dname{1},'\*.las','"',...
                    ' -set_version 1.2 -cores 4 -drop_class 7 9 18 -drop_z_below -2.5 -change_classification_from_to 250 30 -change_classification_from_to 251 31 -odir "',outdir,'"']);
    %%%
    %%% OPTION FILE COPY
    %%%
        % Add to processing directory folder
        copyfile('options_2022version.txt',[bpath,'\',inter_fol,'\',dname{2},'\options.txt']);
        
        % Old way with old RAMBO
        %         copyfile('options.txt',[bpath,'\',inter_fol,'\',dname{2}]);

    %%%
    %%% LAS2BPD
    %%%
        % Set Output to processing_directory and create directory
        outdir=[bpath,'\',inter_fol,'\',dname{2}];
        listing3=dir(outdir);
        listing3(1:2)=[];
        
        % Run Las_Reader_BPD_20181031.exe on each .las file in
        % processing_directory - this creates a .bpd file
        for ccc=1:length(listing3)
            [~,~,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.las'))
                system([gpath{1},' ',outdir,'\',listing3(ccc).name]);
            end
        end
    %%%
    %%% G_FILTER
    %%%
        % Run ground filter on each .bpd file created
        for ccc=1:length(listing3)
            [~,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.las'))
                system([gpath{2},' ',outdir,'\',bb,'.bpd']);
            end
        end
    %%%
    %%% SAVE ORIGINAL CLASS IN USER DATA
    %%%
       % Create directory of Original & Classified .las files
       % and save the original classifications in "User Data" of
       % classified files
       pd_path = [bpath,'\',inter_fol,'\',dname{2},'\*.las'];
       dir_og = dir(pd_path);
       class_path =  [bpath,'\',inter_fol,'\',dname{2},'\output\pointclouds\LASclassified\*.las'];
       dir_class = dir(class_path);
       
       %%% OLD WAY with OLD RAMBO
%        pd_list = dir(pd_path);
%        dir_og = pd_list(~endsWith({pd_list.name},'centroids.las') & ~endsWith({pd_list.name},'classified.las'));   
%        for k = 1:length(dir_og)
%            if exist([dir_og(k).folder,'\',dir_og(k).name(1:end-4),'_classified.las'])
%                s = LASread([dir_og(k).folder,'\',dir_og(k).name]);
%                class1 = s.record.classification;
%                s2 = LASread([dir_og(k).folder,'\',dir_og(k).name(1:end-4),'_classified.las']);
%                s2.record.user_data = class1;
%                LASwrite(s2,[dir_og(k).folder,'\',dir_og(k).name(1:end-4),'_classified.las']);
%            end
%        end   
%        
      for k = 1:length(dir_og)
           if exist([dir_class(k).folder,'\',dir_og(k).name(1:end-4),'_classified.las'])
               s = LASread([dir_og(k).folder,'\',dir_og(k).name]);
               class1 = s.record.classification;
               s2 = LASread([dir_class(k).folder,'\',dir_og(k).name(1:end-4),'_classified.las']);
               s2.record.user_data = class1;
               LASwrite(s2,[dir_og(k).folder,'\',dir_og(k).name(1:end-4),'_classified.las']);
           end
      end
    %%%
    %%% LASCLIP FROM BUFFERED POLYS TO NORMAL POLYS
    %%%
        disp(['lasclip classified tiles into normal polygons...  ',filename])
        % Set Output to reclip_reclass
        outdir = [bpath,'\',inter_fol,'\',dname{3}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        % Clip classified buffered polys into normal polys
        system([lasclip,' -i "',bpath,'\',inter_fol,'\',dname{2},'\*classified.las','"',...
                    ' -poly ',spath{2},' -split -cores 4',...
                    ' -odir "',outdir,'"']);

    %%%
    %%% REMOVE UNNECESARRY FILES (BUFFER OVERLAPS)
    %%%
        % Create directory from reclip_reclass 
        listing3=dir([bpath,'\',inter_fol,'\',dname{3}]);
        listing3(1:2)=[];
        % Delete portions that are overlap
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.las'))                           
                num1=str2num(bb(end-5:end));
                num2=str2num(bb(end-23:end-18));
                if(num1~=num2) 
                    delete([listing3(ccc).folder,'\',listing3(ccc).name]); 
                end
            end
        end

    %%%
    %%% LAS2LAS
    %%%
        disp(['las2las ...  ',filename]) 
        % Set Output to lasclip_ground folder
        outdir = [bpath,'\',inter_fol,'\',dname{4}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        % Output ground data in las files to lasclip_ground folder within
        % Intermediate folder
        system([las2las,' -i "',bpath,'\',inter_fol,'\',dname{3},'\*.las','"',...
                    ' -keep_classification 2 -nad83 -utm 11N -vertical_navd88_geoid12b -cores 4 -odir "',outdir,'" -olas']);
        %%% Set Output to lasclip_nonground folder
        outdir = [bpath,'\',inter_fol,'\',dname{5}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        % Output nonground data in las files to lasclip_nonground folder within
        % Intermediate folder
        system([las2las,' -i "',bpath,'\',inter_fol,'\',dname{3},'\*.las','"',...
                    ' -drop_classification 2 -nad83 -utm 11N -vertical_navd88_geoid12b -cores 4 -odir "',outdir,'" -olas']);

   %%%
   %%% RENAME WITH REAL MOP NUMBERS
   %%%
       if strcmpi(polyStyle, 'mops') == 1
           % Create directory from lasclip_ground
           listing3=dir([bpath,'\',inter_fol,'\',dname{4}]);
           listing3(1:2)=[];
           % Read in FID/MOP Number associations
%            [FID,MOPs] = readvars('polymops2_MOPnum.xls');
           t = readtable(spath{3});
           FID = t(:,1);
           MOPs = t.MOP_num;
           realmop = {};
           % Rename ground files with their actual MOP number
           cd([bpath,'\',inter_fol,'\',dname{4}])
           for ccc=1:length(listing3)
                [~,bb,cc]=fileparts(listing3(ccc).name);
                if(strcmp(cc,'.las'))                           
                    tilenum = str2num(bb(end-5:end));
                    %id_tile = find(FID == tilenum);
                    mopnum = num2str(MOPs(tilenum+1,1),'%05.f');
                    realmop{end+1} = str2num(mopnum);
                    movefile(listing3(ccc).name,[bb(1:8),'_',mopnum,bb(21:end),cc]);
                end
            end
            % Create directory from lasclip_nonground
            listing3=dir([bpath,'\',inter_fol,'\',dname{5}]);
            listing3(1:2)=[];
            % Rename nonground files with their actual MOP number
            cd([bpath,'\',inter_fol,'\',dname{5}])
            for ccc=1:length(listing3)
                [~,bb,cc]=fileparts(listing3(ccc).name);
                if(strcmp(cc,'.las'))                           
                    tilenum = str2num(bb(end-5:end));
                    %id_tile = find(FID == tilenum);
                    mopnum = num2str(MOPs(tilenum+1,1),'%05.f');
                    movefile(listing3(ccc).name,[bb(1:8),'_',mopnum,bb(21:end),cc]);
                end
            end
            % Return to main directory
            cd(bpath)
            
            minmop = num2str(min(cell2mat(realmop)),'%05.f');
            maxmop = num2str(max(cell2mat(realmop)),'%05.f');
            
       else
           % If not the 'mops' polystyle, use original mop nums
           [~,bb,~]=fileparts(filename);
           minmop = bb(10:14);
           maxmop = bb(16:20);
       end
            
    %%%
    %%% SET UP FINAL OUTPUT DIRECTORIES
    %%%
        % Set up Final Output Folders Beach / Backshore
        outbeach = [bpath,'\',final_fol,'\',dname{7}];
        outback = [bpath,'\',final_fol,'\',dname{6}];
        outbackground = [outback,'\',dname{8},'\',dname{9}];
        outbacknon = [outback,'\',dname{8},'\',dname{10}];
        outbeachground = [outbeach,'\',dname{8},'\',dname{9}];
        outbeachnon = [outbeach,'\',dname{8},'\',dname{10}];
        if( exist(outbeach)~=7 & exist(outback)~=7) 
            mkdir(outbeach); 
            mkdir(outback);
            mkdir([outbeach,'\',dname{8}])
            mkdir([outback,'\',dname{8}])
            mkdir(outbeachground)
            mkdir(outbeachnon)
            mkdir(outbackground)
            mkdir(outbacknon)
        end
        
    %%%
    %%% SORT GROUND BEACH AND CLIFF
    %%%
    t = readtable(spath{3});
    FID = t(:,1);
    MOPs = t.MOP_num;
        % Create directory from lasclip_ground folder
        listing3=dir([bpath,'\',inter_fol,'\',dname{4}]);
        listing3(1:2)=[];
        % Read txt files with beach & cliff tile numbers
        tile_class = t.Class;
        % Sort Beach and Cliff ground tiles by number
        for ccc=1:length(listing3)
            [~,bb,cc]=fileparts(listing3(ccc).name);
            % Only operate on .las files
            if(strcmp(cc,'.las'))
                num=str2num(bb(end-5:end));
                if tile_class((num+1),1) == 1
                    copyfile([bpath,'\',inter_fol,'\',dname{4},'\',listing3(ccc).name],outbeachground); 
                else
                    copyfile([bpath,'\',inter_fol,'\',dname{4},'\',listing3(ccc).name],outbackground); 
                end
            end
        end

    %%%
    %%% SORT NON-GROUND BEACH AND CLIFF
    %%%

        % Create directory from lasclip_nonground folder
        listing3=dir([bpath,'\',inter_fol,'\',dname{5}]);
        listing3(1:2)=[];
        % Sort beach and cliff nonground files by number
         for ccc=1:length(listing3)
            [~,bb,cc]=fileparts(listing3(ccc).name);
            % Only operate on .las files
            if(strcmp(cc,'.las'))
                num=str2num(bb(end-5:end));
                if tile_class((num+1),1) == 1
                    copyfile([bpath,'\',inter_fol,'\',dname{5},'\',listing3(ccc).name],outbeachnon); 
                else
                    copyfile([bpath,'\',inter_fol,'\',dname{5},'\',listing3(ccc).name],outbacknon); 
                end
            end
        end

    %%%
    %%% GET SURVEY TIME
    %%% Get a general time for survey from gps time data
        
        % Call GetSurveyTime.m function on input file
        input_fol = [bpath,'\',input_fol];
        surveytime = GetSurveyTime(input_fol,filename);
        
    %%%
    %%% LASMERGE 
    %%% Create full beach_ground.las, cliff_ground.las, and beach_cliff_ground.las
        
        % use filename to edit output name
        [~,bb,~] = fileparts(filename);
        
        % Check to see if there is already a time included, then set
        % output name
        if ~isempty(str2num(bb(22:25)))
            outname = [bb(1:9),minmop,'_',maxmop,bb(21:end)];
        else
            outname = [bb(1:9),minmop,'_',maxmop,'_',surveytime,bb(21:end)];
        end
        
        % Merge all beach ground tiles
        system([lasmerge,' -i "',outbeachground,'\*.las" -odir "',outbeach,'" -o "',outname,'_beach_ground.las"']);
   
        % Merge all cliff ground tiles
        system([lasmerge,' -i "',outbackground,'\*.las" -odir "',outback,'" -o "',outname,'_cliff_ground.las"']);
     
        % Merge full ground .las file of beach and cliff
        system([lasmerge,' -i "',outbeach,'\',outname,'_beach_ground.las" "',outback,'\',outname,'_cliff_ground.las" -odir "',outback,'" -o "',outname,'_beach_cliff_ground.las"']);
        
    %%%
    %%% LASGRID
    %%%
        system([lasgrid,' -i "',outbeach,'\',outname,'_beach_ground.las"' ,' -step 1 -meter -average -elevation -otif -nad83 -utm 11north -vertical_navd88_geoid12b"']);

    %%% 
    %%% MOP TRANSECTS FROM DEM
    %%%
        files = dir([outbeach,'\*.tif']);
        done = extractMOPLidarProfiles(files);
        
%%% DONE
    newfoldername = outname;
    disp(['New folder name is ',outname])

end
        