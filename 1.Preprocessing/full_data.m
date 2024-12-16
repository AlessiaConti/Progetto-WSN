close all; clear; clc;

% Inizializza una tabella per contenere tutti i dati combinati
allPatientData = table();

% Specifica il folder dove si trovano i file CSV /Users/alessandropolverari/Documents/MATLAB/Progetto_WSN/FullDataSet_PD-BioStampRC21
dataFolder = '/Users/alessandropolverari/Documents/MATLAB/Progetto_WSN/FullDataSet_PD-BioStampRC21'; % Modifica con il percorso corretto

% Ottieni la lista di file CSV nella directory
filePattern = fullfile(dataFolder, 'extracted_accel_data_with_updrs_ID*.csv');
csvFiles = dir(filePattern);

% Inizializza l'elenco standard di colonne (sarà ottenuto dal primo file valido)
standardVariableNames = {};

for k = 1:length(csvFiles)
    % Ottieni il nome del file
    csvFileName = csvFiles(k).name;
    fullFilePath = fullfile(dataFolder, csvFileName);
    
    % Mostra il nome del file
    fprintf('Sto elaborando il file: %s\n', csvFileName);

    % Estrai l'ID del paziente dal nome del file
    try
        patientID = extractIDFromFileName(csvFileName);
        fprintf('ID del paziente estratto: %d\n', patientID);
    catch ME
        warning('Errore nell estrazione dell ID per il file %s: %s', csvFileName, ME.message);
        continue;
    end
    
    % Leggi il file CSV
    try
        patientData = readtable(fullFilePath);
        disp('Primi dati letti:');
        disp(head(patientData));
    catch ME
        warning('Errore nella lettura del file %s: %s', csvFileName, ME.message);
        continue;
    end
    
    % Uniforma il tipo di dati per la colonna Medication
    if iscell(patientData.Medication)
        patientData.Medication = string(patientData.Medication);
    end
    
    % Inizializza le colonne standard con la prima tabella valida
    if isempty(standardVariableNames)
        standardVariableNames = patientData.Properties.VariableNames;
        fprintf('Colonne standard inizializzate con: %s\n', strjoin(standardVariableNames, ', '));
    end
    
    % Aggiungi colonne mancanti con valori NaN o rimuovi quelle extra
    missingCols = setdiff(standardVariableNames, patientData.Properties.VariableNames);
    extraCols = setdiff(patientData.Properties.VariableNames, standardVariableNames);
    
    % Debug delle colonne mancanti ed extra
    if ~isempty(missingCols)
        fprintf('Colonne mancanti nel file %s: %s\n', csvFileName, strjoin(missingCols, ', '));
    end
    if ~isempty(extraCols)
        fprintf('Colonne extra nel file %s: %s\n', csvFileName, strjoin(extraCols, ', '));
    end
    
    % Aggiungi le colonne mancanti
    for col = missingCols
        patientData.(col{1}) = NaN; % Usa NaN per colonne numeriche, "" per stringhe se necessario
    end
    
    % Rimuovi le colonne extra
    patientData(:, extraCols) = [];
    
    % Riordina le colonne per rispettare l'ordine standard
    patientData = patientData(:, standardVariableNames);
    
    % Aggiungi una colonna con il PatientID
    patientData.PatientID = repmat(patientID, height(patientData), 1);
    
    % Aggiungi i dati alla tabella finale
    try
        allPatientData = [allPatientData; patientData];
    catch ME
        warning('Errore nella concatenazione per il file %s: %s', csvFileName, ME.message);
        continue;
    end
end

% Controlla se la tabella finale è vuota
if isempty(allPatientData)
    warning('La tabella combinata è vuota. Controllare i file di input.');
else
    
    % Aggiungi una colonna per la durata di ogni prova
    allPatientData.TrialDuration = NaN(height(allPatientData), 1); % Inizializza con valori NaN

    % Trova i valori univoci di PatientID e Index per iterare sui gruppi
    uniquePatients = unique(allPatientData.PatientID);
    for p = uniquePatients'
        patientRows = allPatientData.PatientID == p; % Filtra per paziente
        patientData = allPatientData(patientRows, :); % Estrai i dati del paziente
    
        uniqueIndexes = unique(patientData.Index);
        for idx = uniqueIndexes'
            trialRows = patientData.Index == idx; % Filtra per prova
            trialData = patientData(trialRows, :); % Estrai i dati della prova
        
        % Calcola la durata della prova
        if height(trialData) > 1 % Assicurati che ci siano abbastanza righe per calcolare la durata
            trialDuration = (max(trialData.Timestamp_ms_) - min(trialData.Timestamp_ms_))/1000;
        else
            trialDuration = 0; % Se c'è solo una riga, la durata è zero
        end
        
        % Assegna la durata alla colonna
        allPatientData.TrialDuration(patientRows & allPatientData.Index == idx) = trialDuration;
        end
    end
    % Riordina le colonne per mettere PatientID come prima colonna
    columnOrder = ['PatientID', 'Index', 'EventType','Timestamp_ms_' 'TrialDuration', allPatientData.Properties.VariableNames(~ismember(allPatientData.Properties.VariableNames, {'PatientID', 'Index', 'EventType', 'Duration'}))];
    allPatientData = allPatientData(:, columnOrder);
    % Salva la tabella finale in un file CSV
    outputFileName = fullfile(dataFolder, 'combined_patient_data.csv');
    writetable(allPatientData, outputFileName);

    disp('Tabella combinata creata con successo.');
end

