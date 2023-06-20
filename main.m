% Driver Code

% ---------------------------------------------------------------------------------

% Initializing the mean and standard deviation variables

% Older Variables for NN lstm_1c_0.005_nnet.mat
%{
muX = [49.9997673870878 1365.85573216958 1367.18376475478];
sigmaX = [0.0472558962036959 274.501008104332 269.606176789422];
muY = 1367.30000000000;
sigmaY = 269.647573646088;
%}

% Variables for lstm_1c_256_0.005_nnet.mat
muX = [49.8438098681191 1309.75863330836 1308.85755208464];
sigmaX = [2.70842600153847 322.406414416332 325.828599350139];
muY = 1309.76219117313;
sigmaY = 322.401613792003;


% ---------------------------------------------------------------------------------

powerUpperLimit = 1648;  % Upper limit of the power supplied in MegaWatts
history = 4;  % Number of datapoints it takes to start the prediction
dataTest = zeros(history, 3);
% numPred = 3;  % Number of future predictions to be done in each step

% Loading the trained Neural Network
load lstm_1c_256_0.005_nnet.mat;

tableRowLimit = 10;  % Maximum number of rows the table will display
valueCounter = 0;
stepSize = 50;  % Maximum deviation to be considered negligible
runTime = 1*60*60;  % Hours * 60 * 60 seconds
intervalDuration = 5*60;  % minutes * 60 seconds (Duration between collecting 2 values)

% ===================================================
% Creating User Interface

% Setting up variables
TimeStamp = [];
Block = [];
Frequency = [];
ScheduledGeneration = [];
ActualGeneration = [];
Prediction = [];
    
% Variable Names
varNames = ["Time Stamp", "Block", "Frequency", "Scheduled Generation", "Actual Generation", "Predicted Suggestion"];
    
% Creating UI
f = uifigure("Name", "Power Prediction System", "Position",[20 20 1800 900]);
uit = uitable(f, 'Position',[10 10 1780 300]);
a = uiaxes(f, 'Position', [10 480 1780 400]);
title(a, 'Power Data');
xlabel(a, 'Time Stamp', 'FontSize', 12);
ylabel(a, 'Scheduled Power (MW)', 'FontSize', 12);
grid (a, 'on');

lbl1 = uilabel(f, 'Position', [20 380 500 50]);
lbl1.Text = "<B><font style='color:green;' size='6';>CURRENT SG:</font></B>";
lbl1.Interpreter = "html";

lbl2 = uilabel(f, 'Position', [470 380 600 50]);
lbl2.Text = "<B><font style='color:red'; size='6';>NEXT BLOCK PREDICTION:</font></B>";
lbl2.Interpreter = "html";

lbl3 = uilabel(f, 'Position', [260 382 200 50]);
lbl3.FontSize = 34;
lbl3.FontColor = [0 0.5 0];
lbl3.FontWeight = 'bold';
lbl3.Text = "NaN";

lbl4 = uilabel(f, 'Position', [910 382 200 50]);
lbl4.FontSize = 34;
lbl4.FontColor = [1 0 0];
lbl4.FontWeight = 'bold';
lbl4.Text = "NaN";

lbl5 = uilabel(f, 'Position', [1170 380 600 50]);
lbl5.Text = "<B><font style='color:blue'; size='6';>CURRENT BLOCK:</font></B>";
lbl5.Interpreter = "html";

lbl6 = uilabel(f, 'Position', [1470 382 200 50]);
lbl6.FontSize = 34;
lbl6.FontColor = [0 0 1];
lbl6.FontWeight = 'bold';
lbl6.Text = "NaN";

% ===================================================

% Setting the URLs to fetch data in real time
urlF = 'https://www.upsldc.org/real-time-data?p_p_id=upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=realtimedata&p_p_cacheability=cacheLevelPage&p_p_col_id=column-1&p_p_col_count=1&_upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet_time=1680234586750&_upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet_cmd=realtimedata';
urlP = 'https://www.upsldc.org/real-time-data?p_p_id=upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=unitwisedata&p_p_cacheability=cacheLevelPage&p_p_col_id=column-1&p_p_col_count=1&_upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet_cmd=unitwisedata';
options = weboptions('Timeout', 150);

% ----------------------------------------------------------------------------------
% Creating a data file to store the extracted data
fileID = fopen('data_log.csv', 'a');

% ----------------------------------------------------------------------------------

% Initializing variables
prevFreqData = 0;
temp = 0;
tempSG = 0;

% Mainloop
tic;  % Starting stopwatch
while toc < runTime
    
    % Reading web data
    urlDataF = webread(urlF, options);
    urlDataP = webread(urlP, options);
    
    % ----------------------------------------------------------------------
    
    % Extracting Frequency
    pat1 = '{\"point_id\":\"MUPS.SCADA02.00102650\",\"point_desc\":\"NR FREQUENCY\",\"time_val\"';
    pat2 = ',\"current_revision\":0,\"max_demand\":0.0,\"min_demand\":0.0}"}, {"daynamic_obj":"{\"point_id\":\"MUPS.SCADA02.00113671\"';
    list1 = extractBetween(urlDataF, pat1, pat2);

    webDatetime = extractBetween(list1,':\"', '\",\"point_val');
    freq = extractAfter(list1,'\",\"point_val\":');
    
    pat3 = '"BARA\",\"unit_id\":207,\"unit_name\":\"Unit 3\",\"capacity\":610,\"scada_point_id\":\"MUPS.SCADA02.00053725\",\"point_val\":';
    pat4 = ',\"discom_sg_wl\":0}"}, {"daynamic_obj":"{\"time_block\":0,\"gen_id\":0,\"actual_sch\":0,\"version\":0.0,\"gen_cat\":\"CGS\",\"gen_name\":\"BARA SUIL';
    list2 = extractBetween(urlDataP, pat3, pat4);

    % Extracting Scheduled Generation
    pat5 = ',\"discom_sg_wl\":0}"}, {"daynamic_obj":"{\"time_block\":0,\"gen_id\":0,\"actual_sch\":';
    pat6 = ',\"version\":0.0,\"gen_cat\":\"IPP\",\"unit_id\":0,\"unit_name\":\"Total\",\"capacity\":0,\"point_val\":';
    sch = extractBetween(list2, pat5, pat6);

    % Extracting Actual Generation
    pat7 = ',\"subCatCount\":3,\"actual_sch_dc\":';
    act = extractBetween(list2, pat6, pat7);
    
    % ---------------------------------------------------------------------
    
    % Current time stamp
    currentDateTime = datetime('now');
    predTime = currentDateTime + seconds(intervalDuration);
    
    % Minutes passed since midnight
    currentDate = dateshift(currentDateTime, 'start', 'day');
    minutesPassed = minutes(currentDateTime - currentDate);
    
    % Current Block
    currentBlock = (int64(floor(minutesPassed/15)) + 1);
    blockText = sprintf('%d', currentBlock);
    lbl6.Text = blockText;
    
    % -----------------------------------------------------------------------
    
    if ~isempty(freq)
        disp(webDatetime{1});
        currFreq = str2double(freq{1});  % Current frequency value
        
        % ----------------------------------------------------------------
        
        if (currFreq ~= prevFreqData)
            if isempty(sch)
                finalSch = tempSG;
            else
                finalSch = str2double(sch{1});
            end
            
            finalFreq = str2double(freq{1});
            finalAct = str2double(act{1});
            
            if valueCounter < history
                dataTest(valueCounter+1, :) = [finalFreq finalSch finalAct];
                logFileData = strcat(datestr(currentDateTime), ',', num2str(finalFreq(1)), ',', num2str(finalSch(1)), ',', num2str(finalAct(1)), ',', 'NaN');
                
                TimeStamp = [TimeStamp; currentDateTime];
                Block = [Block; currentBlock];
                Frequency = [Frequency; finalFreq];
                ScheduledGeneration = [ScheduledGeneration; finalSch];
                ActualGeneration = [ActualGeneration; int64(finalAct)];
                Prediction = [Prediction; "NaN"];
                
                % Creating table
                DataTable = table(TimeStamp, Block, Frequency, ScheduledGeneration, ActualGeneration, Prediction, 'VariableNames', varNames);
                
                % Displaying the current prediction values on labels
                currentVal = sprintf('%d' + " MW", finalSch);
                lbl3.Text = currentVal;
                lbl4.Text = "Analysing...";
                
            else
                dataTest(1:end-1, :) = dataTest(2:end, :);
                dataTest(end, :) = [finalFreq finalSch finalAct];
                
                if temp == 0
                    logFileData = strcat(datestr(currentDateTime), ',', num2str(finalFreq(1)), ',', num2str(finalSch(1)), ',', num2str(finalAct(1)), ',', 'NaN');
                else
                    logFileData = strcat(datestr(currentDateTime), ',', num2str(finalFreq(1)), ',', num2str(finalSch(1)), ',', num2str(finalAct(1)), ',', num2str(temp));
                end
                
                X = (dataTest(1:end, :) - muX)./sigmaX;
                [net, Yp] = predictAndUpdateState(net, X', 'SequencePaddingDirection', 'left');
                
                % ----------------------------------------------------------------------------
                % Smoothing the preditions
                deviation = abs((sigmaY*Yp(end) + muY) - finalSch);
                if deviation < stepSize
                    Yp(end) = dataTest(end, 2);
                else
                    Yp(end) = sigmaY*Yp(end) + muY;
                end
                
                % ----------------------------------------------------------------------------
                % Power upper limit
                if Yp(end) > powerUpperLimit
                    Yp(end) = powerUpperLimit;
                end
                
                % Setting the current predicted value to temp variable
                temp = Yp(end);
                tempSG = finalSch;
                
                % Plotting the values on graph
                hold(a, 'on');
                plot(a, predTime, Yp(end), 'rx');
                a.XLim = [(currentDateTime - seconds(10 * intervalDuration)) (currentDateTime + seconds(10 * intervalDuration))];
                hold(a, 'off');
                
                % --------------------------------------------------------------------------
                % Suggesting changes in power
                
                if ((Yp(end) - finalSch) > -20) && ((Yp(end) - finalSch) < 20)
                    Prediction = [Prediction; "No Change"];
                elseif (Yp(end) - finalSch) >= 20
                    Prediction = [Prediction; "Increase"];
                else
                    Prediction = [Prediction; "Decrease"];
                end
                
                TimeStamp = [TimeStamp; currentDateTime];
                Block = [Block; currentBlock];
                Frequency = [Frequency; finalFreq];
                ScheduledGeneration = [ScheduledGeneration; finalSch];
                ActualGeneration = [ActualGeneration; int64(finalAct)];
                
                DataTable = table(TimeStamp, Block, Frequency, ScheduledGeneration, ActualGeneration, Prediction, 'VariableNames', varNames);
                
                % Limiting the number of rows in the table
                if size(DataTable, 1) > tableRowLimit
                    DataTable = DataTable(end - tableRowLimit: end, :);
                end
                
                % Displaying the values on the labels
                currentVal = sprintf('%d' + " MW", finalSch);
                lbl3.Text = currentVal;
                
                predictedVal = sprintf('%d' + " MW", int64(Yp(end)));
                lbl4.Text = predictedVal;
                
            end
            
            % Plotting the values on the graph
            hold(a, 'on');
            plot(a, currentDateTime, finalSch, 'bo');
            a.XLim = [(currentDateTime - seconds(10 * intervalDuration)) (currentDateTime + seconds(10 * intervalDuration))];
            a.YLim = [500 2000];
            hold(a, 'off');
            
            % Updating the variables
            prevFreqData = currFreq;
            valueCounter = valueCounter + 1;
            
            % Printing to data_log file
            fprintf(fileID, '%s', logFileData);
            fprintf(fileID, '\n');
            
            % Printing values to table
            uit.Data = DataTable;
            
            % -------------------------------------------------------------------------------------------------
            % Adding colours to the table rows
            
            [decRow] = find(strcmp(DataTable.("Predicted Suggestion"), 'Decrease'));
            [incRow] = find(strcmp(DataTable.("Predicted Suggestion"), 'Increase'));
            [ncRow] = find(strcmp(DataTable.("Predicted Suggestion"), 'No Change'));
            rc1 = uistyle("BackgroundColor", [1 0.6 0.6]);
            rc2 = uistyle("BackgroundColor", [0.6 1 0.6]);
            
            if ~isempty([decRow])
                addStyle(uit, rc1, "row", [decRow]);
            end
            
            if ~isempty([incRow])
                addStyle(uit, rc1, "row", [incRow]);
            end
            
            if ~isempty([ncRow])
                addStyle(uit, rc2, "row", [ncRow]);
            end
            
            % ------------------------------------------------------------------------------------------------------
            
            drawnow;
            
        end
        
        % ----------------------------------------------------------------
        
    end
    
    % -----------------------------------------------------------------------
    
    pause(intervalDuration)
end

% Closing the data_log file
fclose(fileID);