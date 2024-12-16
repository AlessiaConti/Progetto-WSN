clc; clear all; close all;

% Caricare i dati dal file CSV con features normalizzate
data = readtable('AllFeatures_normalized.csv');

% Definire il nome della variabile target che si vuole bilanciare
% In questo caso quella per la classificazione BINARIA
targetVar = 'Binary_class';

% Convertire la variabile target in tipo stringa (vedere requisiti della mySMOTE)
data.(targetVar) = string(data.(targetVar));

% Selezionare solo le colonne numeriche
numericCols = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
numericData = data(:, numericCols);

% Aggiungere nuovamente la variabile target come ultima colonna
numericData.(targetVar) = data.(targetVar);

% Calcolare il conteggio delle classi
classCounts = groupcounts(data, targetVar);
classLabels = classCounts.(targetVar);
counts = classCounts.GroupCount;

% Individuare l'etichetta della classe minoritaria
[~, minIdx] = min(counts);
minorityLabel = classLabels(minIdx);

% Numero di campioni da aggiungere per bilanciare le classi
numToAdd = max(counts) - min(counts);

% Applicare SMOTE utilizzando la funzione mySMOTE
[newdata, visdata] = mySMOTE(numericData, minorityLabel, numToAdd, 'NumNeighbors', 5);
% 'NumNeighbors': Numero di vicini da considerare per l'interpolazione (default: 5).

% Assegnare nuovi valori di ID_Paziente ai campioni sintetici per distinguerli
startID = 100;  % ID dei nuovi pazienti aggiunti inizia da 100
newdata.ID_Paziente = (startID : startID + height(newdata) - 1)';

% Assegnare valori arrotondati alla colonna Index
newdata.Index = round((1:height(newdata))');

% Unire i nuovi dati sintetici con il dataset originale
balancedData = [numericData; newdata];

% Salvare i dati bilanciati in un nuovo file CSV
writetable(balancedData, 'BinaryClass_balanced.csv');

% Conteggio delle classi prima del bilanciamento
fprintf('\nConteggio Classi Originali:');
disp(groupcounts(data, targetVar));

% Conteggio delle classi dopo il bilanciamento
fprintf('\nConteggio Classi Bilanciate:');
disp(groupcounts(balancedData, targetVar));

fprintf('\nDati bilanciati salvati in BinaryClass_balanced.csv');
