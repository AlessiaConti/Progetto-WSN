clc; clear all; close all;

% Caricamento dati del file CSV completo
data = readtable('combined_patient_data.csv'); 

% Conservare le righe con TrialDuration superiore o uguale a 1
data = data(data.TrialDuration >= 1, :);

% Eliminare specifiche righe per paziente e prova (di durata <1)
data = data(~(data.PatientID == 6 & data.Index == 2), :);
data = data(~(data.PatientID == 35 & data.Index == 1), :);
% (il simbolo ~ nega la condizione)

% Ottenere una lista unica di pazienti
uniquePatients = []; 
for i = 1:height(data) 
    if ~ismember(data.PatientID(i), uniquePatients)
        uniquePatients = [uniquePatients; data.PatientID(i)];
    end
end

% Preallocare una cella per memorizzare le features
% in modo da ottimizzare il codice
numRowsEstimate = 1000; % Stima iniziale del numero di righe
featureCell = cell(numRowsEstimate, 19); % 19 colonne
rowCounter = 0;

% Iterare su ciascun paziente
for p = 1:length(uniquePatients)
    patientID = uniquePatients(p);

    % Filtrare i dati per il paziente corrente
    patientData = data(data.PatientID == patientID, :);

    % Ottenere una lista unica di trial 
    uniqueTrials = [];
    for i = 1:height(patientData)
        if ~ismember(patientData.Index(i), uniqueTrials)
            uniqueTrials = [uniqueTrials; patientData.Index(i)];
        end
    end

    % Iterare su ciascun trial
    for t = 1:length(uniqueTrials)
        trial = uniqueTrials(t);

        % Filtrare i dati per il trial corrente
        trialData = patientData(patientData.Index == trial, :);

        % Ottenere combinazioni uniche di AreaOfBody e Medication 
        uniqueConditions = {};
        for i = 1:height(trialData)
            condition = strcat(trialData.AreaOfBody{i}, '_', trialData.Medication{i});
            if ~any(strcmp(condition, uniqueConditions))
                uniqueConditions = [uniqueConditions; condition];
            end
        end

        % Iterare su ciascuna combinazione (RUE OFF/ON, LUE OFF/ON)
        for c = 1:length(uniqueConditions)
            currentCondition = uniqueConditions{c};
            splitCondition = split(currentCondition, '_');
            areaOfBody = splitCondition{1};
            medication = splitCondition{2};

            % Filtrare i dati per la combinazione corrente
            conditionData = trialData(strcmp(trialData.AreaOfBody, areaOfBody) & ...
                strcmp(trialData.Medication, medication), :);

            % Estrazione delle accelerazioni X, Y, Z
            ax = conditionData.AccelX_g_;
            ay = conditionData.AccelY_g_;
            az = conditionData.AccelZ_g_;

            % Calcolo delle features utilizzando la funzione extract_features
            [Peak, Fo, F50, SF50, features_extr] = features_extraction(ax, ay, az);

            % Estrazione delle features dal vettore features_extr
            maxVal = features_extr(1);
            minVal = features_extr(2);
            meanVal = features_extr(3);
            stdDev = features_extr(4);
            skewnessVal = features_extr(5);
            kurtosisVal = features_extr(6);
            medianVal = features_extr(7);
            peak2peakVal = features_extr(8);
            modeVal = features_extr(9);
            maxPeakVal = features_extr(10);

            % Stima del livello UPDRS utilizzando la funzione stima_UPDRS
            UPDRS_level = stima_UPDRS(Peak, Fo);


            % Estrazione del valore UPDRS dalla tabella
            Label_UPDRS = conditionData.UPDRSValue(1);

            % Accumulare i dati nella cella
            rowCounter = rowCounter + 1;
            featureCell(rowCounter, :) = {Peak, Fo, F50, SF50, maxVal, minVal, meanVal, stdDev, ...
                skewnessVal, kurtosisVal, medianVal, peak2peakVal, modeVal, maxPeakVal,  ...
                string(patientID), string(trial), string(currentCondition), Label_UPDRS, string(UPDRS_level)};
        end
    end
end

% Convertire la cella in una tabella
allFeatures = cell2table(featureCell(1:rowCounter, :), ...
    'VariableNames', {'Peak', 'Fo', 'F50', 'SF50', 'Max', 'Min', 'Mean', 'StdDev', 'Skewness', 'Kurtosis', ...
    'Median', 'Peak2Peak', 'Mode', 'MaxPeak', 'ID_Paziente', 'Index', 'Trial', 'Label_UPDRS', 'Stima_UPDRS'});

% Creare una nuova colonna 'binary_class' nella tabella 'allFeatures'
Binary_class = zeros(height(allFeatures), 1); % Preallocare un vettore di zeri

% Popolare 'binary_class' in base ai valori di 'Label_UPDRS'
for i = 1:height(allFeatures)
    if allFeatures.Label_UPDRS(i) == 0
        Binary_class(i) = 0;
    else
        Binary_class(i) = 1;
    end
end

% Aggiungere la nuova colonna 'binary_class' alla fine della tabella
allFeatures.Binary_class = Binary_class;


% Salvare le features in un nuovo file CSV
writetable(allFeatures, 'AllFeatures.csv');

fprintf('\n>>> Features estratte e salvate nel file "AllFeatures.csv"\n');
