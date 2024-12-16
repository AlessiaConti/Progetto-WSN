% Funzione per estrarre l'ID del paziente dal nome del file
function patientID = extractIDFromFileName(fileName)
    % Cerca il pattern "ID###" nel nome del file
    idMatch = regexp(fileName, 'ID(\d+)', 'tokens');
    if ~isempty(idMatch)
        patientID = str2double(idMatch{1}{1});
    else
        error('Formato del nome del file non valido: impossibile estrarre ID del paziente.');
    end
end