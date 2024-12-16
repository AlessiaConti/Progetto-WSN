clc; clear; close all;

% Carica i dati dal file csv
 annot = readtable("AnnotID038.csv");

% Definisce l'evento target
 targetEventType = 'UPDRS 3.17 - Rest Tremor Amplitude';
 
 % Inizializza la nuova tabella per i dati annot finestrati
 filteredAnnot = table();


% Itera sulle righe della tabella
for i = 1:height(annot)

    % Controlla se la riga corrente ha il tipo di evento target
    if strcmp(annot.EventType{i}, targetEventType)
        % Determina gli indici delle righe da includere
        rowsToInclude = i:min(i+2, height(annot));
        % Controlla il valore dell'ultima riga selezionata
        lastRowValue = annot.Value{rowsToInclude(end)};
        if ismember(lastRowValue, {'RUE', 'LUE'})
            % Aggiungi le righe alla nuova tabella
            filteredAnnot = [filteredAnnot; annot(rowsToInclude, :)];
        end
    end
end

% Visualizza il risultato
% disp(filteredAnnot);

% Prealloca variabili per la nuova tabella
numRows = sum(strcmp(filteredAnnot.EventType, 'UPDRS 3.17 - Rest Tremor Amplitude'));
eventType = cell(numRows, 1);
startTime = zeros(numRows, 1);
stopTime = zeros(numRows, 1);
medication = cell(numRows, 1);
areaOfBody = cell(numRows, 1);
durata = zeros(numRows,1);

% Indice per la nuova tabella
newRowIndex = 1;

% Ciclo sulle righe di filteredAnnot 
for i = 1:height(filteredAnnot)
    if strcmp(filteredAnnot.EventType{i}, 'UPDRS 3.17 - Rest Tremor Amplitude')
        % Ottieni dati dalla riga UPDRS 3.17 - Rest Tremor Amplitude
        eventType{newRowIndex} = filteredAnnot.EventType{i};
        startTime(newRowIndex) = filteredAnnot.('StartTimestamp_ms_')(i);
        stopTime(newRowIndex) = filteredAnnot.('StopTimestamp_ms_')(i);
        % durata(newRowIndex) = (stopTime - startTime)/1000;
        % Cerca righe successive per Medication e Area of Body
        medicationFound = false;
        areaOfBodyFound = false;
        for j = i+1:height(filteredAnnot)
            % Associa lo stato della Medication
            if strcmp(filteredAnnot.EventType{j}, 'Medication:')
                medication{newRowIndex} = filteredAnnot.Value{j};
                medicationFound = true;
            end
            
            % Associa il valore di Area of Body
            if strcmp(filteredAnnot.EventType{j}, 'Area of the body:')
                areaOfBody{newRowIndex} = filteredAnnot.Value{j};
                areaOfBodyFound = true;
            end
            
            % Se entrambe le informazioni sono trovate, interrompi il ciclo
            if medicationFound && areaOfBodyFound
                break;
            end
        end
        
        % Incrementa l'indice della nuova tabella
        newRowIndex = newRowIndex + 1;
    end
end

% Crea la nuova tabella Annot
combinedDataAnnot = table(eventType, startTime, stopTime, medication, areaOfBody, ...
                     'VariableNames', {'EventType', 'StartTime', 'StopTime', 'Medication', 'AreaOfBody'});

% Visualizza la nuova tabella Annot
disp(combinedDataAnnot);

% Leggi i file accelerometrici
lhData = readtable('lh_ID038Accel.csv'); % File accelerometrico LUE (Left Upper Extremity)
rhData = readtable('rh_ID038Accel.csv'); % File accelerometrico RUE (Right Upper Extremity)
lhData.Properties.VariableNames(1) = "Timestamp_ms_";
rhData.Properties.VariableNames(1) = "Timestamp_ms_";
% Tabella per salvare i dati estratti
extracted_accel_Data = [];

% Inizializza l'indice delle prove nella tabella combinedDataAnnot
Index = 1; % Primo trial
combinedDataAnnot.Index = zeros(height(combinedDataAnnot), 1); % Aggiungi colonna per i trial

% Assegna l'indice dei trial
for i = 1:height(combinedDataAnnot)
    if i > 1
        % Verifica se c'è un cambio di AreaOfBody o Medication rispetto alla riga precedente
        if ~strcmp(combinedDataAnnot.AreaOfBody{i}, combinedDataAnnot.AreaOfBody{i-1}) || ...
           ~strcmp(combinedDataAnnot.Medication{i}, combinedDataAnnot.Medication{i-1})
            Index = Index + 1; % Incrementa l'indice dei trial
        end
    end
    % Assegna l'indice alla riga corrente
    combinedDataAnnot.Index(i) = Index;
end

% Ciclo su ogni riga della tabella combinedDataAnnot
disp('Inizio elaborazione eventi...');
for i = 1:height(combinedDataAnnot)
    % Ottieni i dettagli dell'evento
    startTime = combinedDataAnnot.StartTime(i);
    stopTime = combinedDataAnnot.StopTime(i);
    % durata = combinedDataAnnot.durata(i);
    areaOfBody = combinedDataAnnot.AreaOfBody{i};
    medicationStatus = combinedDataAnnot.Medication{i};
    Index = combinedDataAnnot.Index(i); % Indice della prova corrente
    
    % Filtra i dati appropriati in base all'Area of Body
    if strcmp(areaOfBody, 'LUE')
        disp(['Filtrando dati per LUE, evento ', num2str(i)]);
        filteredAccelData = lhData(lhData.Timestamp_ms_ >= startTime & lhData.Timestamp_ms_ <= stopTime, :);
    elseif strcmp(areaOfBody, 'RUE')
        disp(['Filtrando dati per RUE, evento ', num2str(i)]);
        filteredAccelData = rhData(rhData.Timestamp_ms_ >= startTime & rhData.Timestamp_ms_ <= stopTime, :);
    else
        disp(['Area of Body non riconosciuta per l''evento ', num2str(i)]);
        continue; % Salta all'iterazione successiva
    end
    
    % Aggiungi colonne per identificare AreaOfBody, Medication e Index
    if ~isempty(filteredAccelData)
        % filteredAccelData.durata = repmat({durata},height(filteredAccelData),1);
        filteredAccelData.AreaOfBody = repmat({areaOfBody}, height(filteredAccelData), 1); % Colonna LUE/RUE
        filteredAccelData.Medication = repmat({medicationStatus}, height(filteredAccelData), 1); % Colonna ON/OFF
        filteredAccelData.Index = repmat(Index, height(filteredAccelData), 1); % Colonna Index
       

        % Accoda i dati filtrati
        extracted_accel_Data = [extracted_accel_Data; filteredAccelData]; 
        extracted_accel_Data.Properties.VariableNames(2) = "AccelX_g_";
        extracted_accel_Data.Properties.VariableNames(3) = "AccelY_g_";
        extracted_accel_Data.Properties.VariableNames(4) = "AccelZ_g_";
    end
end

% Nome del file di annotazione
annotFileName = 'AnnotID038.csv'; % Inserire il nome corretto del file qui

% Estrazione dell'ID del paziente dal nome del file
patientID = extractPatientIDFromFileName(annotFileName);

% Carica la tabella clinica
clinicData = readtable('Clinic_DataPDBioStampRCStudy.csv');

% Aggiungi una colonna per i valori UPDRS
extracted_accel_Data.UPDRSValue = nan(height(extracted_accel_Data), 1); % Inizializzata a NaN

% Ciclo su ogni riga della tabella accelerometrica estratta
for i = 1:height(extracted_accel_Data)
    % Ottieni le informazioni correnti
    areaOfBody = extracted_accel_Data.AreaOfBody{i};
    medicationStatus = extracted_accel_Data.Medication{i};
    
    % Trova la riga corrispondente nella tabella clinica
    clinicRow = clinicData(clinicData.ID == patientID, :);
    
    if isempty(clinicRow)
        warning('Paziente ID %d non trovato nella tabella clinica.', patientID);
        continue; % Salta al prossimo loop
    end
    
    % Determina la colonna UPDRS da usare
    if strcmp(areaOfBody, 'RUE')
        if isempty(medicationStatus) % Caso senza ON/OFF
            updrsColumn = 'updrs_3_17a';
        elseif strcmp(medicationStatus, 'ON')
            updrsColumn = 'updrs_3_17a_on';
        elseif strcmp(medicationStatus, 'OFF')
            updrsColumn = 'updrs_3_17a_off';
        else
            warning('Stato Medication non riconosciuto: %s', medicationStatus);
            continue; % Salta al prossimo loop
        end
    elseif strcmp(areaOfBody, 'LUE')
        if isempty(medicationStatus) % Caso senza ON/OFF
            updrsColumn = 'updrs_3_17b';
        elseif strcmp(medicationStatus, 'ON')
            updrsColumn = 'updrs_3_17b_on';
        elseif strcmp(medicationStatus, 'OFF')
            updrsColumn = 'updrs_3_17b_off';
        else
            warning('Stato Medication non riconosciuto: %s', medicationStatus);
            continue; % Salta al prossimo loop
        end
    else
        warning('Area of Body non riconosciuta: %s', areaOfBody);
        continue; % Salta al prossimo loop
    end
    
    % Recupera il valore UPDRS corrispondente
    if ismember(updrsColumn, clinicData.Properties.VariableNames)
        extracted_accel_Data.UPDRSValue(i) = clinicRow.(updrsColumn);
    else
        warning('Colonna %s non trovata nella tabella clinica.', updrsColumn);
    end
    
    % Aggiorna il valore di EventType
    extracted_accel_Data.EventType{i} = updrsColumn;
end

% Riorganizza le colonne della tabella
colOrder = [{'Index', 'EventType'}, setdiff(extracted_accel_Data.Properties.VariableNames, {'Index', 'EventType'})];
extracted_accel_Data = extracted_accel_Data(:, colOrder);

% Visualizza i risultati
disp(extracted_accel_Data);

% Salva i dati aggiornati in un nuovo file CSV
writetable(extracted_accel_Data, 'extracted_accel_data_with_updrs_ID038.csv');
disp('Dati accelerometrici con valori UPDRS salvati in "extracted_accel_data_with_updrs.csv".');



