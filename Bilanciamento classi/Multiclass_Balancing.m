clc; clear all;

% Caricare i dati dal file CSV
data = readtable('AllFeatures_normalized.csv');


% Rimuovere la colonna 'Trial' da data (non è numerica e non serve)
if any(strcmp('Trial', data.Properties.VariableNames))
    data.Trial = [];
end

% Convertire la variabile target Label_UPDRS in tipo stringa
data.Label_UPDRS = string(data.Label_UPDRS);

% Selezionare solo le colonne numeriche per le features
features = data(:, varfun(@isnumeric, data, 'OutputFormat', 'uniform'));

% Creare una tabella con le features numeriche e Label_UPDRS come ultima colonna
smoteData = [features, table(data.Label_UPDRS)];

% Rinomina della variabile target per chiarezza
smoteData.Properties.VariableNames{end} = 'Label_UPDRS';

% Calcolare il conteggio delle classi per Label_UPDRS
classCounts = groupcounts(smoteData, 'Label_UPDRS');
classLabels = classCounts.Label_UPDRS;
counts = classCounts.GroupCount;

% Determinare la classe con il numero massimo di campioni
maxCount = max(counts);

% Inizializzare una tabella per i nuovi dati sintetici
newdata = [];

% Applicare SMOTE per ciascuna classe minoritaria
for i = 1:length(classLabels)
    currentLabel = classLabels(i);
    currentCount = counts(i);
    
    % Se la classe è minoritaria, applicare SMOTE
    if currentCount < maxCount
        numToAdd = maxCount - currentCount;
        fprintf('Generazione di %d campioni sintetici per la classe %s\n', numToAdd, currentLabel);
        
        % Applicare mySMOTE per la classe corrente
        [newdataClass, ~] = mySMOTE(smoteData, currentLabel, numToAdd, 'NumNeighbors', 5);
        
        % Assegnare nuovi valori distintivi per ID_Paziente e Index
        newdataClass.ID_Paziente = (100 + i) * ones(height(newdataClass), 1);
        newdataClass.Index = round((1:height(newdataClass))');
        
        % Aggiungere i nuovi dati sintetici alla tabella dei nuovi dati
        newdata = [newdata; newdataClass];
    end
end

% Unire i nuovi dati sintetici con il dataset originale
balancedData = [data; newdata];

% Visualizzare il conteggio delle classi prima del bilanciamento per Label_UPDRS
fprintf('\nConteggio Classi Prima del Bilanciamento per Label_UPDRS:');
disp(groupcounts(data, 'Label_UPDRS'));

% Visualizzare il conteggio delle classi bilanciate
disp('Conteggio Classi Bilanciate per Label_UPDRS:');
disp(groupcounts(balancedData, 'Label_UPDRS'));

% Salvare i dati bilanciati in un nuovo file CSV
writetable(balancedData, 'MultiClass_Balanced.csv');
fprintf('\nDati bilanciati salvati in MultiClass_Balanced.csv\n');