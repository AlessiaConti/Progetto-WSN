

% Caricare i dati dal file CSV
data = readtable('AllFeatures.csv');

% Inizializzare i contatori per Binary_class
contBinary0 = 0;
contBinary1 = 0;

% Inizializzare i contatori per Label_UPDRS
contUPDRS0 = 0;
contUPDRS1 = 0;
contUPDRS2 = 0;
contUPDRS3 = 0;
contUPDRS4 = 0;

% Iterare su tutte le righe della tabella
for i = 1:height(data)
    % Contare le occorrenze per Binary_class
    if data.Binary_class(i) == 0
        contBinary0 = contBinary0 + 1;
    elseif data.Binary_class(i) == 1
        contBinary1 = contBinary1 + 1;
    end

    % Contare le occorrenze per Label_UPDRS
    if data.Label_UPDRS(i) == 0
        contUPDRS0 = contUPDRS0 + 1;
    elseif data.Label_UPDRS(i) == 1
        contUPDRS1 = contUPDRS1 + 1;
    elseif data.Label_UPDRS(i) == 2
        contUPDRS2 = contUPDRS2 + 1;
    elseif data.Label_UPDRS(i) == 3
        contUPDRS3 = contUPDRS3 + 1;
    elseif data.Label_UPDRS(i) == 4
        contUPDRS4 = contUPDRS4 + 1;
    end
end

% Visualizzare i risultati per Binary_class
fprintf('\nConteggio per classificazione binaria:\n');
fprintf('classe 0 (non tremore) | occorrenze %d\n', contBinary0);
fprintf('classe 1 (tremore) | occorrenze %d\n', contBinary1);

% Visualizzare i risultati per Label_UPDRS
fprintf('\nConteggio per classificazione multiclasse:\n');
fprintf('classe 0 | occorrenze %d\n', contUPDRS0);
fprintf('classe 1 | occorrenze %d\n', contUPDRS1);
fprintf('classe 2 | occorrenze %d\n', contUPDRS2);
fprintf('classe 3 | occorrenze %d\n', contUPDRS3);
fprintf('classe 4 | occorrenze %d\n', contUPDRS4);
