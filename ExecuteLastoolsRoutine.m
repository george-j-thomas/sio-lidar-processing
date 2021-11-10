function [newfoldername] = ExecuteLastoolsRoutine(filename, foldername, polyStyle)

bpath = 'D:\LidarProcessing_Level2';
lbase = 'C:\LAStools\bin\';

%%% INPUT & OUTPUT PATH 
rpath{1} = '\\reefbreak\group\LiDAR\VMZ2000_Truck\LiDAR_Processed_Level1\';
rpath{2} = 'D:\LiDAR_Processed_Level2\';

%%% LASTOOLS PATH
lpath{1} = [lbase,'las2las.exe'];
lpath{2} = [lbase,'lasclip.exe'];
lpath{3} = [lbase,'lasinfo.exe'];
lpath{4} = [lbase,'las2las.exe'];
lpath{5} = [lbase,'las2las.exe'];
lpath{6} = [lbase,'lasclip.exe'];
lpath{7} = [lbase,'lasmerge.exe'];
lpath{8} = [lbase,'lasgrid.exe'];
lpath{9} = [lbase,'txt2las.exe'];

%%% PROCESSING FOLDER 1
bname{1} = '0_Input_Files';
bname{2} = '1_Intermediate_Files';
bname{3} = '2_Final_Output_Files';

%%% PROCESSING FOLDER 2
dname{1}='las2las_out';
dname{2}='lasclip_out';
dname{3}='processing_directory';
dname{4}='ground';
dname{5}='nonground';
dname{6}='lasclip_ground';
dname{7}='lasclip_nonground';
dname{8}='beach_ground';
dname{9}='cliff_ground';
dname{10}='beach_nonground';
dname{11}='cliff_nonground';
dname{12}='beach_cliff_ground';
dname{13}='beach_1m_gridded';
dname{14}='Beach_And_Backshore';
dname{15}='Beach_Only';
dname{16}='Tiles';
dname{17}='Ground';
dname{18}='Nonground';

%%% GROUND FILTER PATH
gpath{1}=[bpath,'\Olsen_Ground_Filter\TriRAI_20181031\Las_Reader_BPD_20181031.exe'];
gpath{2}=[bpath,'\Olsen_Ground_Filter\TriRAI_20181031\TriRAI_20181031.exe'];

%%% SET DESIRED POLYGON PATH
if strcmpi(polyStyle, 'poly3') == 1
    %%% ORIGINAL POLY3 SHAPEFILE PATH
    spath{1}=[bpath,'\Lidar_Polygons\poly3_buffer.shp'];
    spath{2}=[bpath,'\Lidar_Polygons\poly3.shp'];
    spath{3}=[bpath,'\Lidar_Polygons\poly3_beach.txt'];
    spath{4}=[bpath,'\Lidar_Polygons\poly3_cliff.txt'];
elseif strcmpi(polyStyle, 'mops') == 1
    %%% MOP SHAPEFILE PATH
    spath{1}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\polymopsbuffer2.shp'];
    spath{2}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\polymops2.shp'];
    spath{3}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\polymops_beach.txt'];
    spath{4}=[bpath,'\MOP_Polygons\V2_ComplexBackbeach\polymops_cliff.txt'];
elseif strcmpi(polyStyle, 'malibu') == 1
    %%% MOP SHAPEFILE PATH
    spath{1}=[bpath,'\MOP_Polygons\Malibu\MalibuPolyBuffer.shp'];
    spath{2}=[bpath,'\MOP_Polygons\Malibu\MalibuPoly.shp'];
    spath{3}=[bpath,'\MOP_Polygons\Malibu\polymops_beach.txt'];
    spath{4}=[bpath,'\MOP_Polygons\Malibu\polymops_cliff.txt'];
else
    disp('Not a valid polygon style, must be "poly3", "mops", or "malibu"')
end

%%% TEMPORARY FILES CONTAINING PROCESSING FILE NAME
tname{1}=[bpath,'\','lasfile_list1.txt'];
tname{2}=[bpath,'\','lasfile_list2.txt'];


%%%
%%% BEGIN
%%%

    %%%
    %%% LASCLIP INTO BUFFERED POLYGONS
    %%%
        disp(['lasclip into buffered polys ...  ',filename])
        %%% Set Output to lasclip_out
        outdir = [bpath,'\',bname{2},'\',dname{2}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        %%% Lasclip into buffered polygons
        system([lpath{2},' -i "',bpath,'\',bname{1},'\',filename,'"',...
        ' -poly ',spath{1},' -split',...
        ' -odir "',outdir,'"']);
    %%%
    %%% LAS INFO, REMOVE IF POINT NUMBER < 10
    %%% get info from each file - spit to txt file - check if pnum<10
        disp(['lasinfo ...  ',filename])
        %%% Create directory from lasclip_out
        listing3=dir(outdir);
        listing3(1:2)=[];
        %%% Las Info - Spit to .txt
        for ccc=1:length(listing3)
            system([lpath{3},' -i "',bpath,'\',bname{2},'\',dname{2},'\',listing3(ccc).name,'" -otxt']);
        end
        % Re-Create directory from lasclip_out
        listing3=dir(outdir);
        listing3(1:2)=[];
        %%% Find Number of Points in file
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.txt'))
                fid = fopen([outdir,'\',listing3(ccc).name]);
                dummy = textscan(fid,'%s','delimiter','\n');
                TextAsCells = dummy{1,1};
                fclose(fid);
                
                v_mask = ~cellfun(@isempty, strfind(TextAsCells, 'version major.minor'));
                v_line = TextAsCells(v_mask);
                veee = cell2mat(v_line);
                lnum=findstr(veee,':');
                vnum=str2num(veee(lnum+1:end));
                
                %%% Find number of points depending on las version
                if vnum == 1.4
                    mask = ~cellfun(@isempty, strfind(TextAsCells, 'extended number of point records'));
                    p_line = TextAsCells(mask);
                    eee = cell2mat(p_line);
                    lnum=findstr(eee,':');
                    pnum=str2num(eee(lnum+1:end));
                else
                    mask = ~cellfun(@isempty, strfind(TextAsCells, 'number of point records'));
                    p_line = TextAsCells(mask);
                    eee = cell2mat(p_line(1));
                    lnum=findstr(eee,':');
                    pnum=str2num(eee(lnum+1:end));
                end
                
                %%% Delete lasinfo .txt file
                delete([outdir,'\',listing3(ccc).name]);

                %%% Delete .las tile if pnum<10
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
        listing3=dir(outdir);
        listing3(1:2)=[];
        
        outdir = [bpath,'\',bname{2},'\',dname{3}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.las'))
                system([lpath{4},' -i "',bpath,'\',bname{2},'\',dname{2},'\',listing3(ccc).name,'"',...
                    ' -set_version 1.2 -drop_class 7 9 18 -change_classification_from_to 250 30 -change_classification_from_to 251 31 -odir "',outdir,'"']);
            end
        end
    %%%
    %%% OPTION FILE COPY
    %%%
        %%% Add to processing directory folder
        copyfile('options.txt',[bpath,'\',bname{2},'\',dname{3}]);
    %%%
    %%% CREATE FILE NAME FILE
    %%%
        %%% Set Output to Input_Files and create directory
        outdir=[bpath,'\',bname{1}];
        listing3=dir(outdir);
        listing3(1:2)=[];
        
        %%% Create lasfile_list1.txt from Input_Files folder
        fid=fopen(tname{1},'w');
        for ccc=1:length(listing3)
            fprintf(fid,'%s\n',listing3(ccc).name);
        end
        fclose(fid);
        
        %%% Create lasfile_list2.txt from lasclip_out folder
        outdir=[bpath,'\',bname{2},'\',dname{2}];
        listing3=dir(outdir);
        listing3(1:2)=[];
        fid=fopen(tname{2},'w');
        for ccc=1:length(listing3)
            fprintf(fid,'%s\n',listing3(ccc).name);
        end
        fclose(fid);
    %%%
    %%% LAS2BPD
    %%%
        %%% Set Output to processing_directory and create directory
        outdir=[bpath,'\',bname{2},'\',dname{3}];
        listing3=dir(outdir);
        listing3(1:2)=[];
        
        %%% Run Las_Reader_BPD_20181031.exe on each .las file in
        %%% processing_directory - this creates a .bpd file
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.las'))
                system([gpath{1},' ',outdir,'\',listing3(ccc).name]);
            end
        end
    %%%
    %%% G_FILTER
    %%%
        %%% Run ground filter on each .bpd file created
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.las'))
                system([gpath{2},' ',outdir,'\',bb,'.bpd']);
            end
        end
    %%%
    %%% SAVE ORIGINAL CLASS IN USER DATA
    %%%
       %%% Create directory of Original & Classified .las files
       %%% and save the original classifications in "User Data" of
       %%% classified files
%        pd_path = [bpath,'\',bname{2},'\',dname{3},'\*.las'];
%        pd_list = dir(pd_path);
%        dir_og = pd_list(~endsWith({pd_list.name},'centroids.las') & ~endsWith({pd_list.name},'classified.las'));
%        dir_class = pd_list(endsWith({pd_list.name},'classified.las'));
%        for k = 1:length(dir_og)
%            s = LASread([dir_og(k).folder,'\',dir_og(k).name]);
%            class1 = s.record.classification;
%            s2 = LASread([dir_class(k).folder,'\',dir_class(k).name]);
%            s2.record.user_data = class1;
%            LASwrite(s2,[dir_class(k).folder,'\',dir_class(k).name]);
%        end   
    %%%
    %%% LAS2LAS
    %%%
        disp(['las2las ...  ',filename]) % asdf
        %%% Create directory from processing_directory
        outdir=[bpath,'\',bname{2},'\',dname{3}];
        listing3=dir(outdir);
        listing3(1:2)=[];
        %%% Set Output to ground folder
        outdir = [bpath,'\',bname{2},'\',dname{4}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        %%% Output ground data in las files to ground folder within
        %%% Intermediate folder
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if( strcmp(cc,'.las') & strcmp(bb(end-9:end),'classified'))
                system([lpath{5},' -i "',bpath,'\',bname{2},'\',dname{3},'\',listing3(ccc).name,'"',...
                    ' -keep_classification 2 -nad83 -utm 11N -vertical_navd88_geoid12b -odir "',outdir,'" -olas']);
            end
        end
        %%% Set Output to nonground folder
        outdir = [bpath,'\',bname{2},'\',dname{5}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        %%% Output nonground data in las files to nonground folder within
        %%% Intermediate folder
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if( strcmp(cc,'.las') & strcmp(bb(end-9:end),'classified'))
                system([lpath{5},' -i "',bpath,'\',bname{2},'\',dname{3},'\',listing3(ccc).name,'"',...
                    ' -drop_classification 2 -nad83 -utm 11N -vertical_navd88_geoid12b -odir "',outdir,'" -olas']);
            end
        end
    %%%
    %%% LASCLIP FROM BUFFERED POLYS TO NORMAL POLYS
    %%%
        disp(['lasclip into normal polygons...  ',filename])
        %%% Set Output to lasclip_ground
        outdir = [bpath,'\',bname{2},'\',dname{6}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        %%% Clip ground buffered polys into normal polys
        listing3=dir([bpath,'\',bname{2},'\',dname{4}]);
        listing3(1:2)=[];
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if( strcmp(cc,'.las') & strcmp(bb(end-9:end),'classified'))
                system([lpath{6},' -i "',bpath,'\',bname{2},'\',dname{4},'\',listing3(ccc).name,'"',...
                    ' -poly ',spath{2},' -split ',...
                    ' -odir "',outdir,'"']);
            end
        end
        %%% Set Ouput to lasclip_nonground
        outdir = [bpath,'\',bname{2},'\',dname{7}];
        if( exist(outdir)~=7 ) 
            mkdir(outdir); 
        end
        %%% Clip nonground buffered polys into normal polys
        listing3=dir([bpath,'\',bname{2},'\',dname{5}]);
        listing3(1:2)=[];
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if( strcmp(cc,'.las') & strcmp(bb(end-9:end),'classified'))
                system([lpath{6},' -i "',bpath,'\',bname{2},'\',dname{5},'\',listing3(ccc).name,'"',...
                    ' -poly ',spath{2},' -split ',...
                    ' -odir "',outdir,'"']);
            end
        end
    %%%
    %%% REMOVE UNNECESARRY FILES (BUFFER OVERLAPS)
    %%%
        %%% Create directory from lasclip_ground 
        listing3=dir([bpath,'\',bname{2},'\',dname{6}]);
        listing3(1:2)=[];
        %%% Delete portions that are overlap
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
        %%% Create directory from lasclip_nonground
        listing3=dir([bpath,'\',bname{2},'\',dname{7}]);
        listing3(1:2)=[];
        %%% Delete portions that are overlap
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
   %%% RENAME WITH REAL MOP NUMBERS
   %%%
       if strcmpi(polyStyle, 'mops') == 1
           %%% Create directory from lasclip_ground
           listing3=dir([bpath,'\',bname{2},'\',dname{6}]);
           listing3(1:2)=[];
           %%% Read in FID/MOP Number associations
           [FID,MOPs] = readvars('polymops2_MOPnum.xls');
           realmop = {};
           %%% Rename ground files with their actual MOP number
           cd([bpath,'\',bname{2},'\',dname{6}])
           for ccc=1:length(listing3)
                [aa,bb,cc]=fileparts(listing3(ccc).name);
                if(strcmp(cc,'.las'))                           
                    tilenum = str2num(bb(end-5:end));
                    %id_tile = find(FID == tilenum);
                    mopnum = num2str(MOPs(FID == tilenum),'%05.f');
                    realmop{end+1} = str2num(mopnum);
                    movefile(listing3(ccc).name,[bb(1:8),'_',mopnum,bb(21:end),cc]);
                end
            end
            %%% Create directory from lasclip_nonground
            listing3=dir([bpath,'\',bname{2},'\',dname{7}]);
            listing3(1:2)=[];
            %%% Rename nonground files with their actual MOP number
            cd([bpath,'\',bname{2},'\',dname{7}])
            for ccc=1:length(listing3)
                [aa,bb,cc]=fileparts(listing3(ccc).name);
                if(strcmp(cc,'.las'))                           
                    tilenum = str2num(bb(end-5:end));
                    %id_tile = find(FID == tilenum);
                    mopnum = num2str(MOPs(FID == tilenum),'%05.f');
                    movefile(listing3(ccc).name,[bb(1:8),'_',mopnum,bb(21:end),cc]);
                end
            end
            %%% Return to main directory
            cd(bpath)
       end
       
       minmop = num2str(min(cell2mat(realmop)),'%05.f');
       maxmop = num2str(max(cell2mat(realmop)),'%05.f');
       
       
    %%%
    %%% SET UP FINAL OUTPUT DIRECTORIES
    %%%
        %%% Set up Final Output Folders Beach / Backshore
        outbeach = [bpath,'\',bname{3},'\',dname{15}];
        outback = [bpath,'\',bname{3},'\',dname{14}];
        outbackground = [outback,'\',dname{16},'\',dname{17}];
        outbacknon = [outback,'\',dname{16},'\',dname{18}];
        outbeachground = [outbeach,'\',dname{16},'\',dname{17}];
        outbeachnon = [outbeach,'\',dname{16},'\',dname{18}];
        if( exist(outbeach)~=7 & exist(outback)~=7) 
            mkdir(outbeach); 
            mkdir(outback);
            mkdir([outbeach,'\',dname{16}])
            mkdir([outback,'\',dname{16}])
            mkdir(outbeachground)
            mkdir(outbeachnon)
            mkdir(outbackground)
            mkdir(outbacknon)
        end
    %%%
    %%% SORT GROUND BEACH AND CLIFF
    %%%

        %%% Create directory from lasclip_ground folder
        listing3=dir([bpath,'\',bname{2},'\',dname{6}]);
        listing3(1:2)=[];
        %%% Read txt files with beach & cliff tile numbers
        bnum=dlmread(spath{3});
        cnum=dlmread(spath{4});
        %%% Sort Beach and Cliff ground tiles by number
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            %%% Only operate on .las files
            if(strcmp(cc,'.las'))
                num=str2num(bb(end-5:end));
                %%% Sort Beach Tiles to beach_ground folder
                for ddd=1:length(bnum) 
                    if(bnum(ddd)==num) 
                        copyfile([bpath,'\',bname{2},'\',dname{6},'\',listing3(ccc).name],outbeachground); 
                    end
                end
                %%% Sort Cliff Tiles to cliff_ground folder
                for ddd=1:length(cnum) 
                    if(cnum(ddd)==num) 
                        copyfile([bpath,'\',bname{2},'\',dname{6},'\',listing3(ccc).name],outbackground); 
                    end
                end
            end
        end
    %%%
    %%% SORT NON-GROUND BEACH AND CLIFF
    %%%

        %%% Create directory from lasclip_nonground folder
        listing3=dir([bpath,'\',bname{2},'\',dname{7}]);
        listing3(1:2)=[];
        %%% Sort beach and cliff nonground files by number
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            %%% Only operate on .las files
            if(strcmp(cc,'.las'))
                num=str2num(bb(end-5:end));
                %%% Sort Beach Tiles to beach_nonground folder
                for ddd=1:length(bnum) 
                    if(bnum(ddd)==num) 
                        copyfile([bpath,'\',bname{2},'\',dname{7},'\',listing3(ccc).name],outbeachnon); 
                    end
                end
                %%% Sort Cliff Tiles to cliff_nonground folder
                for ddd=1:length(cnum) 
                    if(cnum(ddd)==num) 
                        copyfile([bpath,'\',bname{2},'\',dname{7},'\',listing3(ccc).name],outbacknon); 
                    end
                end
            end
        end
                            
    %%%
    %%% LASMERGE 
    %%% Create full beach_ground.las, cliff_ground.las, and beach_cliff_ground.las
        
        %%% Get list from lasfile_list1.txt
        fid = fopen(tname{1}); 
        ddd=textscan(fid,'%s','delimiter','\n'); 
        fclose(fid); 
        eee=cell2mat(ddd{1}); 
        [aa,bb,cc]=fileparts(eee); 
        outname = [bb(1:9),minmop,'_',maxmop,bb(21:end)];
        
        %%% Merge all beach ground tiles
        system([lpath{7},' -i "',outbeachground,'\*.las" -odir "',outbeach,'" -o "',outname,'_beach_ground.las"']);
   
        %%% Merge all cliff ground tiles
        system([lpath{7},' -i "',outbackground,'\*.las" -odir "',outback,'" -o "',outname,'_cliff_ground.las"']);
     
        %%% Merge full ground .las file of beach and cliff
        system([lpath{7},' -i "',outbeach,'\',outname,'_beach_ground.las" "',outback,'\',outname,'_cliff_ground.las" -odir "',outback,'" -o "',outname,'_beach_cliff_ground.las"']);
        
        %%% Copy full merged file to final output files folder
        %copyfile([outdir,'\',bb,'_beach_cliff_ground.las'],outback);
    %%%
    %%% LASGRID
    %%%
        system([lpath{8},' -i "',outbeach,'\',outname,'_beach_ground.las"' ,' -step 1 -meter -average -elevation -otif -nad83 -utm 11north -vertical_navd88_geoid12b"']);

        
%%% DONE
    newfoldername = outname;
    disp(['New folder name is ',outname])

end
        