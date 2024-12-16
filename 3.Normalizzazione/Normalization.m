close all;
clear all;
clc;

% La normalizzazione Min-Max trasforma ogni valore delle features(x) in un 
% range specifico[0:1] utilizzando la formula X'= (X-Xmin)/(Xmax-Xmin) 

% Carico tabella contenente tutte le Features 
AllFeatures = readtable("AllFeatures.csv");

% Seleziono solo le colonne da normalizzare della tabella
numericData = AllFeatures(:, 1:14); 

% Creazione di una nuova tabella per i dati normalizzati
dataNormalized = numericData; % Copia delle colonne da normalizzare in una variabile di appoggio

% Normalizzo ogni colonna separatamente
for col = 1:width(numericData)
    colData = numericData{:, col}; % Estraggo i dati della colonna
    minValue = min(colData);       % Valore minimo della colonna
    maxValue = max(colData);       % Valore massimo della colonna
    dataNormalized{:, col} = (colData - minValue) / (maxValue - minValue); % Normalizzo come formula sopra
end

% Crea una nuova tabella combinando i dati non normalizzati e quelli numerici normalizzati
AllFeatures_normalized = [dataNormalized, AllFeatures(:, 15:20)];

% Salvo le features normalizzate in un nuovo file CSV
writetable(AllFeatures_normalized, 'AllFeatures_normalized.csv');

fprintf('\n>>> Features estratte e salvate nel file "AllFeatures_normalized.csv"\n');