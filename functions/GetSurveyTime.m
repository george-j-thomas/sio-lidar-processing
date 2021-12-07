function [surveytime] = GetSurveyTime(folderpath,name)
    %%% Reads in LAS file and determines a general start time for survey
    %%% based offthe gps times found in the file. Times are in one of ~3
    %%% formats:
    %%% (1) Adjusted Standard GPS time: Seconds since the start of GPS time 
    %%%     (Jan 6, 1980), *minus* 1 billion seconds. This is the standard 
    %%%     way to represent gps time and is a much larger number than 
    %%%     times in the second method below.
    %%% (2) GPS Time of the Week: Seconds since midnight of the previous 
    %%%     Sunday.  Easy to tell if it is in this setup because it will 
    %%%     be less than the number of seconds in a week: 604,800. May also
    %%%     be since midnight of survey date
    
    %%% Read in file and get times
        s = LASread([folderpath,'\',name]);
        mintime = min(s.record.gps_time);
        medtime = median(s.record.gps_time);
        maxtime = max(s.record.gps_time);
    
    %%% Set # of secs in week and epoch of gps start date + 1 billion
    %%% seconds
        weeksecs = 60*60*24*7;
        gpsplus1b = datetime(2011,9,14,1,46,40,'Timezone','UTCLeapSeconds');
    %%% Grab date of survey from file name
        filedate = datetime(name(1:8),'InputFormat','yyyyMMdd');
        filedate.TimeZone = 'America/Los_Angeles';
        surveytime = {};
    
    if mintime > weeksecs
        %%% If first gps time # seconds is greater than number of secs in a
        %%% week, time is in standard adjusted gps time
        tUTC = gpsplus1b + seconds(mintime);
        tLST = tUTC + tzoffset(filedate);
        tUTC_med = gpsplus1b + seconds(medtime);
        tLST_med = tUTC_med + tzoffset(filedate);
        if day(tLST) == day(filedate)
            surveyhour = sprintf('%02.f',hour(tLST));
            surveymin = sprintf('%02.f',minute(tLST));
            surveytime = [surveyhour,surveymin];
        elseif day(tLST_med) == day(filedate)
            surveyhour = sprintf('%02.f',hour(tLST_med));
            surveymin = sprintf('%02.f',minute(tLST_med));
            surveytime = [surveyhour,surveymin];
        end
    else
        %%% If first gps time # seconds is less than number of secs in a
        %%% week, time is in gps time of the week (seconds since sunday) or
        %%% seconds since midnight
        leapsecs = 18;
        intime = mintime;

        [~,tLSTsun] = GPStoUTC(intime,name,leapsecs);
        [~,tLSTmid] = GPStoUTC_midnightStart(intime,name,leapsecs);

        LSTsun = datetime(tLSTsun,'ConvertFrom','datenum');
        LSTmid = datetime(tLSTmid,'ConvertFrom','datenum');

        if day(LSTsun) == day(filedate)
            surveyhour = sprintf('%02.f',hour(LSTsun));
            surveymin = sprintf('%02.f',minute(LSTsun));
            surveytime = [surveyhour,surveymin];
        elseif day(LSTmid) == day(filedate)
            surveyhour = sprintf('%02.f',hour(LSTmid));
            surveymin = sprintf('%02.f',minute(LSTmid));
            surveytime = [surveyhour,surveymin];
        end
    end
    
    if isempty(surveytime) == 1
        %%% If previous methods do not work, try with median timestamp
        %%% of survey
        leapsecs = 18;
        intime = medtime;

        [~,tLSTsun] = GPStoUTC(intime,name,leapsecs);
        [~,tLSTmid] = GPStoUTC_midnightStart(intime,name,leapsecs);

        LSTsun = datetime(tLSTsun,'ConvertFrom','datenum');
        LSTmid = datetime(tLSTmid,'ConvertFrom','datenum');

        if day(LSTsun) == day(filedate)
            surveyhour = sprintf('%02.f',hour(LSTsun));
            surveymin = sprintf('%02.f',minute(LSTsun));
            surveytime = [surveyhour,surveymin];
        elseif day(LSTmid) == day(filedate)
            surveyhour = sprintf('%02.f',hour(LSTmid));
            surveymin = sprintf('%02.f',minute(LSTmid));
            surveytime = [surveyhour,surveymin];
        end
    end
    
    %%% If no methods return a datetime on the correct survey date
    if isempty(surveytime) == 1
        disp('No methods found correct survey date, setting time to 0000')
        surveytime = '0000';
    end
end

    
    
