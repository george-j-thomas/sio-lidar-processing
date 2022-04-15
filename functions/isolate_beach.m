function [outfile,outfolder,beach_done] = isolate_beach(lasfilename,folder)

    bpath = pwd;
    lbase = 'C:\LAStools\bin\';

    lasclip = [lbase,'lasclip.exe'];
    lasinfo = [lbase,'lasinfo.exe'];
    lasmerge = [lbase,'lasmerge.exe'];

    dpath = 'D:\LidarProcessing_Level2';
    spath{1}=[dpath,'\MOP_Polygons\V2_ComplexBackbeach\SD_ManualBackbeach_polys_buffer.shp'];
    spath{2}=[dpath,'\MOP_Polygons\V2_ComplexBackbeach\SD_ManualBackbeach_polys.shp'];
    spath{3}=[dpath,'\MOP_Polygons\V2_ComplexBackbeach\SD_ManualBackbeach_table.txt'];
    
    beachpath = [bpath,'\beach_isolation'];
    
    fname{1} = [beachpath,'\beach_input'];
    fname{2} = [beachpath,'\beach_inter'];
    fname{3} = [beachpath,'\beach_tiles'];
    fname{4} = [beachpath,'\beach_output'];
    
    for k = 1:length(fname)
        if( exist(fname{k})~=7 ) 
            mkdir(fname{k}); 
        end
    end
    
    %%% Clear Input/Intermediate/Tile Folders
        rmdir(fname{1},'s')
        rmdir(fname{2},'s')
        rmdir(fname{3},'s')
        
        for k = 1:length(fname)
            if( exist(fname{k})~=7 ) 
                mkdir(fname{k}); 
            end
        end

    %%% Copy las file
        outdir = fname{1};
        copyfile([folder,'\',lasfilename],outdir);
        
        indir = dir(outdir);
        indir(1:2) = [];
        
    %%% Separate into MOP Polygons (Unbuffered)
        outdir = fname{2};

        system([lasclip,' -i "',fname{1},'\',indir.name,'"',...
        ' -poly ',spath{2},' -split',...
        ' -nad83 -utm 11N -vertical_navd88_geoid12b',' -olas',' -odir "',outdir,'"']);
        clipdir = dir(outdir);
        clipdir(1:2) = [];
    %%% Find Beach tiles only
        outdir = fname{3};

        %%% Read txt files with beach tile numbers
        t = readtable(spath{3});
        tile_class = t.Class;

        %%% Copy beach files to dem_beachtiles folder
        for ccc=1:length(clipdir)
            [~,bb,cc]=fileparts(clipdir(ccc).name);
            %%% Only operate on .las files
            if(strcmp(cc,'.las'))
                num=str2num(bb(end-5:end));
                if tile_class((num+1),1) == 1
                        copyfile([clipdir(ccc).folder,'\',clipdir(ccc).name],outdir);        
                end
            end
        end
    %%%
    %%% LAS INFO, REMOVE IF POINT NUMBER < 1000
    %%% get info from each file - spit to txt file - check if pnum<10
        %%% Create directory from lasclip_out
        listing3=dir(fname{3});
        listing3(1:2)=[];
        %%% Las Info - Spit to .txt
        for ccc=1:length(listing3)
            system([lasinfo,' -i "',fname{3},'\',listing3(ccc).name,'"',' -otxt']);
        end
        % Re-Create directory from lasclip_out
        listing3=dir(fname{3});
        listing3(1:2)=[];
        %%% Find Number of Points in file
        for ccc=1:length(listing3)
            [aa,bb,cc]=fileparts(listing3(ccc).name);
            if(strcmp(cc,'.txt'))
                fid = fopen([fname{3},'\',listing3(ccc).name]);
                ddd = textscan(fid,'%s',1,'delimiter','\n', 'headerlines',15);
                ddd2 = textscan(fid,'%s',1,'delimiter','\n', 'headerlines',8);
                fclose(fid);
                delete([fname{3},'\',listing3(ccc).name]);
                eee = cell2mat(ddd{1});
                lnum=findstr(eee,':');
                pnum=str2num(eee(lnum+1:end));
                
                eee2 = cell2mat(ddd2{1});
                lnum=findstr(eee2,':');
                pnum2=str2num(eee2(lnum+1:end));
              
                %%% Delete if pnum<1000
                if( pnum<10 && pnum2 < 1000 ) 
                    delete([fname{3},'\',bb,'.las']); 
                end
            end
        end
        
        
    %%% Merge the beach tiles
        outdir = fname{4};

        [~,bb,~]=fileparts(lasfilename);
        system([lasmerge,' -i "',fname{3},'\*.las','"',' -o "',bb(1:9),bb(30:end),'_beach.las','"',' -odir "',outdir,'"'])
        
    %%% Set Output values
        outfile = [bb(1:9),bb(30:end),'_beach.las'];
        outfolder = outdir;
        beach_done = 1;
end