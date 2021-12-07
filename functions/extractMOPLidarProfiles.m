function [done] = extractMOPLidarProfiles(files)

warning('off', 'map:geotiff:undefinedGTModelTypeGeoKey')
moptable = readtable('MopXY.csv');

for f = 1:length(files)
    if isfile([files(f).folder,'\',files(f).name(1:end-4),'_moptransects.txt']) == 0

        %%% Get filename & MOP Number bounds
        tiffile = files(f).name;
        tfname = split(tiffile,'/');
        tfname = tfname{end};
        fsplit = split(tfname,'_');
        smop = str2double(fsplit{2});
        nmop = str2double(fsplit{3});

        %%% Turn UTM coords to lat/lon
        cd(files(f).folder)
        [surv,R]=geotiffread(tiffile);
        surv=double(surv);
        % Extract data array indices with elevations
        [icorr,jcorr,sinds]=find(surv > -9999);
        zsurv=surv(surv > -9999);
        % Assign utm coordinates to each elevation
        eutm=R.XWorldLimits(1)+jcorr;
        nutm=R.YWorldLimits(2)-icorr;
        % convert utm coords to lat lons
        [ysurv,xsurv]=utm2deg(eutm,nutm,repmat('11 N',[length(eutm) 1]));
        clearvars tiffile fsplit surv R icorr jcorr sinds

        %%% Isolate mops in the survey area
        amop=fliplr(smop:nmop)';
        % Assign survey points to the nearest mop line based on closest
        %  mop backbeach point, use survey #1 y value with cosine latitude
        %  for consistent local scaling
        [dp,imop]=pdist2([moptable.BackLon(amop)*cosd(ysurv(1)),moptable.BackLat(amop)],...
            [xsurv*cosd(ysurv(1)),ysurv],'euclidean','Smallest',1);

        %%% Get all distances from survey points to closest mop
        distall = NaN(size(xsurv));
        xlen = length(xsurv);
        res =  0.0000225;
        for d = 1:length(xsurv)
            v1 = [moptable.BackLon(amop(imop(d))),moptable.BackLat(amop(imop(d))),0];
            v2 = [moptable.OffLon(amop(imop(d))),moptable.OffLat(amop(imop(d))),0];
            pt = [xsurv(d),ysurv(d),0];
            a = v1 - v2;
            b = pt - v2;
            dist = norm(cross(a,b)) / norm(a);
            distall(d) = dist;
        end

        kpts = find(distall < res);
        mopnums = amop(imop(kpts));
        xsurv = xsurv(kpts);
        ysurv = ysurv(kpts);
        zsurv = zsurv(kpts);
        eutm = eutm(kpts);
        nutm = nutm(kpts);
        clearvars a amop b d dist distall dp imop nmop pt smop v1 v2 xlen

        %%% Save to text file (lat lon northings eastings elevation mop)
        mopoutput = [ysurv,xsurv,nutm,eutm,zsurv,mopnums]';
        outname = sprintf('%s_moptransects.txt',tfname(1:end-4));
        fileID = fopen(outname,'w');
        fprintf(fileID,'%f %f %f %f %f %d\n',mopoutput);
        fclose(fileID);

        done = 1;
        if done == 1
            disp(['Extracted Profiles from ',tfname])
        end
    end
end


    % -------------------------------------------------------------------------
    function  [Lat,Lon] = utm2deg(xx,yy,utmzone)
    % -------------------------------------------------------------------------
    % [Lat,Lon] = utm2deg(x,y,utmzone)
    %
    % Description: Function to convert vectors of UTM coordinates into Lat/Lon vectors (WGS84).
    % Some code has been extracted from deg2utm.m function by Rafael Palacios.
    %
    % Inputs:
    %    x, y , utmzone.
    %
    % Outputs:
    %    Lat: Latitude vector.   Degrees.  +ddd.ddddd  WGS84
    %    Lon: Longitude vector.  Degrees.  +ddd.ddddd  WGS84
    %
    % Example 1:
    % x=[ 458731;  407653;  239027;  230253;  343898;  362850];
    % y=[4462881; 5126290; 4163083; 3171843; 4302285; 2772478];
    % utmzone=['30 T'; '32 T'; '11 S'; '28 R'; '15 S'; '51 R'];
    % [Lat, Lon]=utm2deg(x,y,utmzone);
    % fprintf('%11.6f ',lat)
    %    40.315430   46.283902   37.577834   28.645647   38.855552   25.061780
    % fprintf('%11.6f ',lon)
    %    -3.485713    7.801235 -119.955246  -17.759537  -94.799019  121.640266
    %
    % Example 2: If you need Lat/Lon coordinates in Degrees, Minutes and Seconds
    % [Lat, Lon]=utm2deg(x,y,utmzone);
    % LatDMS=dms2mat(deg2dms(Lat))
    %LatDMS =
    %    40.00         18.00         55.55
    %    46.00         17.00          2.01
    %    37.00         34.00         40.17
    %    28.00         38.00         44.33
    %    38.00         51.00         19.96
    %    25.00          3.00         42.41
    % LonDMS=dms2mat(deg2dms(Lon))
    %LonDMS =
    %    -3.00         29.00          8.61
    %     7.00         48.00          4.40
    %  -119.00         57.00         18.93
    %   -17.00         45.00         34.33
    %   -94.00         47.00         56.47
    %   121.00         38.00         24.96
    %
    % Authors: 
    %   Erwin Nindl, Rafael Palacious
    %
    % Version history by Erwin Nindl:
    %   Nov/13: removed main-loop and vectorised all calculations
    %
    % Version history by Rafael Palacios:
    %   Apr/06, Jun/06, Aug/06, Aug/06
    %   Aug/06: fixed a problem (found by Rodolphe Dewarrat) related to southern 
    %     hemisphere coordinates. 
    %   Aug/06: corrected m-Lint warnings
    %---------------------------------------------------------------------------

        % Argument checking
        %
        error(nargchk(3, 3, nargin)); %3 arguments required
        n1=length(xx);
        n2=length(yy);
        n3=size(utmzone,1);
        if (n1~=n2 || n1~=n3)
           error('x,y and utmzone vectors should have the same number or rows');
        end
        c=size(utmzone,2);
        if (c~=4)
           error('utmzone should be a vector of strings like "30 T"');
        end



        % % Memory pre-allocation
        % %
        % Lat=zeros(n1,1);
        % Lon=zeros(n1,1);


        % Avoid Main Loop
        %

        if(~isempty(find(utmzone(:,4)>'X',1)) || ~isempty(find(utmzone(:,4)<'C',1)))
          fprintf('utm2deg: Warning utmzone should be a vector of strings like "30 T", not "30 t"\n');
        end

        hemis = char(zeros(n1,1));
        hemis(:) = 'S';
        hemis(utmzone(:,4)>'M') = 'N'; % Northern hemisphere

        x = xx(:);
        y = yy(:);
        zone = str2num(utmzone(:,1:2));

        sa = 6378137.000000 ; sb = 6356752.314245;

        %   e = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sa;
        e2 = ( ( ( sa .^ 2 ) - ( sb .^ 2 ) ) .^ 0.5 ) ./ sb;
        e2cuadrada = e2 .^ 2;
        c = ( sa .^ 2 ) ./ sb;
        %   alpha = ( sa - sb ) / sa;             %f
        %   ablandamiento = 1 / alpha;   % 1/f
        X = x - 500000;
        Y = y;
        ids_south = (hemis == 'S') | (hemis == 's');
        Y(ids_south) = Y(ids_south) - 10000000;

        S = ( ( zone .* 6 ) - 183 ); 
        lat =  Y ./ ( 6366197.724 .* 0.9996 );                                    
        v = ( c ./ ( ( 1 + ( e2cuadrada .* ( cos(lat) ) .^ 2 ) ) ) .^ 0.5 ) .* 0.9996;
        a = X ./ v;
        a1 = sin( 2 .* lat );
        a2 = a1 .* ( cos(lat) ) .^ 2;
        j2 = lat + ( a1 ./ 2 );
        j4 = ( ( 3 .* j2 ) + a2 ) ./ 4;
        j6 = ( ( 5 .* j4 ) + ( a2 .* ( cos(lat) ) .^ 2) ) ./ 3;
        alfa = ( 3 ./ 4 ) .* e2cuadrada;
        beta = ( 5 ./ 3 ) .* alfa .^ 2;
        gama = ( 35 ./ 27 ) .* alfa .^ 3;
        Bm = 0.9996 .* c .* ( lat - alfa .* j2 + beta .* j4 - gama .* j6 );
        b = ( Y - Bm ) ./ v;
        Epsi = ( ( e2cuadrada .* a.^2 ) ./ 2 ) .* ( cos(lat) ).^ 2;
        Eps = a .* ( 1 - ( Epsi ./ 3 ) );
        nab = ( b .* ( 1 - Epsi ) ) + lat;
        senoheps = ( exp(Eps) - exp(-Eps) ) ./ 2;
        Delt = atan(senoheps ./ (cos(nab) ) );
        TaO = atan(cos(Delt) .* tan(nab));
        longitude = (Delt .* (180/pi) ) + S;

        latitude = ( lat + ( 1 + e2cuadrada .* (cos(lat).^2) - ( 3/2 ) ...
          .* e2cuadrada .* sin(lat) .* cos(lat) .* ( TaO - lat ) ) ...
          .* ( TaO - lat ) ) .* (180/pi);

        Lat = latitude;
        Lon = longitude;
    end
end