% Driver Code

% ---------------------------------------------------------------------------------
% Loading the system variables

% Variables for 15 minutes prediction
load variables_15.mat;

% Variables for 45 minutes prediction
load variables_45.mat;

% Variables for frequency prediction
load trainingVariables.mat

% ---------------------------------------------------------------------------------

powerUpperLimit = 1648;  % Upper limit of the power supplied in MegaWatts
history = 1;  % Number of datapoints it takes to start the prediction
dataTest = zeros(history, 3);
numPred = 3;  % Number of future predictions to be done in each step

% Loading the trained Neural Networks
load lstm_15-min_nnet.mat;
load lstm_45-min_nnet.mat;
load FNN_100eph_0.005LR.mat;

tableRowLimit = 10;  % Maximum number of rows the table will display
valueCounter = 0;
stepSize = 50;  % Maximum deviation to be considered negligible
runTime = 2*24*60*60;  % Hours * 60 * 60 seconds
intervalDuration = 5*60;  % minutes * 60 seconds (Duration between collecting 2 values)

% ===================================================
% Creating User Interface

% Setting up variables
TimeStamp = [];
Block = [];
Frequency = [];
PredictedFrequency = [];
ScheduledGeneration = [];
ActualGeneration = [];
Prediction_15 = [];
Prediction_45 = [];
Prediction_S = [];
    
% Variable Names
varNames = ["Time Stamp", "Block", "Frequency", "Frequency Prediction", "Scheduled Generation", "Actual Generation", "(n+1) Prediction", "(n+3) Prediction", "Predicted Suggestion"];
    
% Creating UI
f = uifigure("Name", "Prediction System", "Position", [20 20 1800 900]);
tabgp = uitabgroup(f, 'Position', [10 380 1780 500]);
tab1 = uitab(tabgp, 'Title', 'Frequency');
tab2 = uitab(tabgp, 'Title', 'Scheduled Power');

uit = uitable(f, 'Position',[10 10 1780 360]);

% Scheduled Power Plot
a = uiaxes(tab2, 'Position', [10 10 1760 350]);
title(a, 'Power Data');
xlabel(a, 'Time Stamp', 'FontSize', 12);
ylabel(a, 'Scheduled Power (MW)', 'FontSize', 12);
grid(a, 'on');

% Frequency Plot
af = uiaxes(tab1, 'Position', [10 10 1760 350]);
title(af, 'Frequency Data');
xlabel(af, 'Time Stamp', 'FontSize', 12);
ylabel(af, 'Frequency (Hz)', 'FontSize', 12);
grid(af, 'on');

lbl1 = uilabel(tab2, 'Position', [20 380 500 50]);
lbl1.Text = "<B><font style='color:green;' size='6';>Current SG:</font></B>";
lbl1.Interpreter = "html";

lbl2 = uilabel(tab2, 'Position', [450 380 600 50]);
lbl2.Text = "<B><font style='color:red'; size='6';> N+3rd Block Prediction:</font></B>";
lbl2.Interpreter = "html";

lbl3 = uilabel(tab2, 'Position', [210 382 200 50]);
lbl3.FontSize = 34;
lbl3.FontColor = [0 0.5 0];
lbl3.FontWeight = 'bold';
lbl3.Text = "NaN";

lbl4 = uilabel(tab2, 'Position', [830 382 200 50]);
lbl4.FontSize = 34;
lbl4.FontColor = [1 0 0];
lbl4.FontWeight = 'bold';
lbl4.Text = "NaN";

lbl5 = uilabel(tab1, 'Position', [1170 380 600 50]);
lbl5.Text = "<B><font style='color:blue'; size='6';>Current Block:</font></B>";
lbl5.Interpreter = "html";

lbl6 = uilabel(tab1, 'Position', [1520 382 200 50]);
lbl6.FontSize = 34;
lbl6.FontColor = [0 0 1];
lbl6.FontWeight = 'bold';
lbl6.Text = "NaN";

lbl7 = uilabel(tab1, 'Position', [20 380 500 50]);
lbl7.Text = "<B><font style='color:green;' size='6';>Frequency:</font></B>";
lbl7.Interpreter = "html";

lbl8 = uilabel(tab1, 'Position', [460 380 600 50]);
lbl8.Text = "<B><font style='color:red'; size='6';>Next Block Prediction:</font></B>";
lbl8.Interpreter = "html";

lbl9 = uilabel(tab1, 'Position', [220 382 200 50]);
lbl9.FontSize = 34;
lbl9.FontColor = [0 0.5 0];
lbl9.FontWeight = 'bold';
lbl9.Text = "NaN";

lbl10 = uilabel(tab1, 'Position', [810 382 200 50]);
lbl10.FontSize = 34;
lbl10.FontColor = [1 0 0];
lbl10.FontWeight = 'bold';
lbl10.Text = "NaN";

lbl11 = uilabel(tab2, 'Position', [1170 380 600 50]);
lbl11.Text = "<B><font style='color:blue'; size='6';>Current Block:</font></B>";
lbl11.Interpreter = "html";

lbl11 = uilabel(tab2, 'Position', [1520 382 200 50]);
lbl11.FontSize = 34;
lbl11.FontColor = [0 0 1];
lbl11.FontWeight = 'bold';
lbl11.Text = "NaN";


% ===================================================

% Setting the URLs to fetch data in real time
urlF = 'https://www.upsldc.org/real-time-data?p_p_id=upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=realtimedata&p_p_cacheability=cacheLevelPage&p_p_col_id=column-1&p_p_col_count=1&_upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet_time=1680234586750&_upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet_cmd=realtimedata';
urlP = 'https://www.upsldc.org/real-time-data?p_p_id=upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=unitwisedata&p_p_cacheability=cacheLevelPage&p_p_col_id=column-1&p_p_col_count=1&_upgenerationsummary_WAR_UPSLDCDynamicDisplayportlet_cmd=unitwisedata';
options = weboptions('Timeout', 150);

% ----------------------------------------------------------------------------------

% Initializing variables
prevFreqData = 0;
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
    pred_15_Time = currentDateTime + seconds(intervalDuration);
    pred_45_Time = currentDateTime + 3*seconds(intervalDuration);
    
    % Minutes passed since midnight
    currentDate = dateshift(currentDateTime, 'start', 'day');
    minutesPassed = minutes(currentDateTime - currentDate);
    
    % Current Block
    currentBlock = (int64(floor(minutesPassed/15)) + 1);
    blockText = sprintf('%d', currentBlock);
    lbl6.Text = blockText;
    lbl11.Text = blockText;
    
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
                
                TimeStamp = [TimeStamp; currentDateTime];
                Block = [Block; currentBlock];
                Frequency = [Frequency; finalFreq];
                PredictedFrequency = [PredictedFrequency; "NaN"];
                ScheduledGeneration = [ScheduledGeneration; finalSch];
                ActualGeneration = [ActualGeneration; int64(finalAct)];
                Prediction_15 = [Prediction_15; "NaN"];
                Prediction_45 = [Prediction_45; "NaN"];
                Prediction_S = [Prediction_S; "NaN"];
                
                % Creating table
                DataTable = table(TimeStamp, Block, Frequency, PredictedFrequency, ScheduledGeneration, ActualGeneration, Prediction_15, Prediction_45, Prediction_S, 'VariableNames', varNames);
                
                % Displaying the current prediction values on labels
                currentVal = sprintf('%d' + " MW", finalSch);
                lbl3.Text = currentVal;
                lbl4.Text = "Analysing...";
                cf = sprintf('%.4f' + " Hz", finalFreq(end));
                lbl9.Text = cf;
                lbl10.Text = "Analysing...";
                
            else
                dataTest(1:end-1, :) = dataTest(2:end, :);
                dataTest(end, :) = [finalFreq finalSch finalAct];
                
                X_15 = (dataTest(1:end, :) - muX_15)./sigmaX_15;
                X_45 = (dataTest(1:end, :) - muX_45)./sigmaX_45;
                X_f = (dataTest(1:end, :) - muX)./sigmaX;

                [net_15, Yp_15] = predictAndUpdateState(net_15, X_15', 'SequencePaddingDirection', 'left');
                [net_45, Yp_45] = predictAndUpdateState(net_45, X_45', 'SequencePaddingDirection', 'left');
                [net_f, Yp_f] = predictAndUpdateState(net_f, X_f', 'SequencePaddingDirection', 'left');
                
                
                % ----------------------------------------------------------------------------
                % Smoothing the preditions
                deviation = abs((sigmaY_15*Yp_15(end) + muY_15) - finalSch);
                if deviation < stepSize
                    Yp_15(end) = dataTest(end, 2);
                else
                    Yp_15(end) = sigmaY_15*Yp_15(end) + muY_15;
                end
                
                deviation = abs((sigmaY_45*Yp_45(end) + muY_45) - finalSch);
                if deviation < stepSize
                    Yp_45(end) = dataTest(end, 2);
                else
                    Yp_45(end) = sigmaY_45*Yp_45(end) + muY_15;
                end

                % ----------------------------------------------------------------------------
                % Power upper limit
                if Yp_15(end) > powerUpperLimit
                    Yp_15(end) = powerUpperLimit;
                end

                if Yp_45(end) > powerUpperLimit
                    Yp_45(end) = powerUpperLimit;
                end
                
                Yp_f(end) = sigmaY*Yp_f(end) + muY;
                
                % Setting the current predicted value to temp variable
                tempSG = finalSch;
                
                % Plotting power the values on graph
                hold(a, 'on');
                plot(a, pred_15_Time, Yp_15(end), 'rx', 'MarkerSize', 10, 'LineWidth', 5);
                plot(a, pred_45_Time, Yp_45(end), 'bx', 'MarkerSize', 10, 'LineWidth', 5);
                a.XLim = [(currentDateTime - seconds(10 * intervalDuration)) (currentDateTime + seconds(10 * intervalDuration))];
                hold(a, 'off');
                
                % Plotting frequency the values on graph
                hold(af, 'on');
                plot(af, pred_15_Time, Yp_f(end), 'rx','MarkerSize', 10, 'LineWidth', 5);
                af.XLim = [(currentDateTime - seconds(10 * intervalDuration)) (currentDateTime + seconds(10 * intervalDuration))];
                hold(af, 'off');
                
                % --------------------------------------------------------------------------
                % Suggesting changes in power
                
                if ((Yp_45(end) - finalSch) > -20) && ((Yp_45(end) - finalSch) < 20)
                    Prediction_S = [Prediction_S; "No Change"];
                elseif (Yp_45(end) - finalSch) >= 20
                    Prediction_S = [Prediction_S; "Increase"];
                else
                    Prediction_S = [Prediction_S; "Decrease"];
                end
                
                TimeStamp = [TimeStamp; currentDateTime];
                Block = [Block; currentBlock];
                Frequency = [Frequency; finalFreq];
                PredictedFrequency = [PredictedFrequency; (Yp_f)];
                ScheduledGeneration = [ScheduledGeneration; finalSch];
                ActualGeneration = [ActualGeneration; int64(finalAct)];
                Prediction_15 = [Prediction_15; int64(Yp_15(end))];
                Prediction_45 = [Prediction_45; int64(Yp_45(end))];
                
                DataTable = table(TimeStamp, Block, Frequency, ScheduledGeneration, ActualGeneration, Prediction_15, Prediction_45, Prediction_S, 'VariableNames', varNames);
                
                % Limiting the number of rows in the table
                if size(DataTable, 1) > tableRowLimit
                    DataTable = DataTable(end - tableRowLimit: end, :);
                end
                
                % Displaying the values on the labels
                currentVal = sprintf('%d' + " MW", finalSch);
                lbl3.Text = currentVal;
                
                %predictedVal = sprintf('%d', Prediction_S(end));
                lbl4.Text = Prediction_S(end);
                lbl9.Text = sprintf('%.4f' + " Hz", finalFreq);
                lbl10.Text = sprintf('%.4f' + " Hz", Yp_f);
                
                
            end
            
            % Plotting the power values on the graph
            hold(a, 'on');
            plot(a, currentDateTime, finalSch, 'bo', 'MarkerSize', 10, 'LineWidth', 3);
            a.XLim = [(currentDateTime - seconds(10 * intervalDuration)) (currentDateTime + seconds(10 * intervalDuration))];
            a.YLim = [500 2000];
            hold(a, 'off');
            
            % Plotting the frequency values on the graph
            hold(af, 'on');
            plot(af, currentDateTime, finalFreq, 'bo', 'MarkerSize', 10, 'LineWidth', 3);
            af.XLim = [(currentDateTime - seconds(10 * intervalDuration)) (currentDateTime + seconds(10 * intervalDuration))];
            af.YLim = [49.6 50.4];
            hold(af, 'off');
            
            % Updating the variables
            prevFreqData = currFreq;
            valueCounter = valueCounter + 1;
            
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