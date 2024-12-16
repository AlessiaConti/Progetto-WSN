

function [level] = stima_UPDRS(peak, freq)

% Funzione per stimare il livello UPDRS dalle features estratte
%
% INPUT:
%   peak        - Picco della densità spettrale di potenza
%   freq          - Frequenza associata al picco massimo
%
% OUTPUT:
%   level        - Stima del livello UPDRS

fprintf('> Correlazione con scala UPDRS:\n');
level=0; 

% Correlazione con scala UPDRS
if peak < 5
    fprintf('UPDRS level: 0\n');
    level=0;
elseif peak >= 5 && peak <= 32
    fprintf('UPDRS level: 1\n');
    level=1;
elseif peak > 32 && peak <= 200
    fprintf('UPDRS level: 2\n');
    level=2;
elseif peak > 200 && peak <= 300
    fprintf('UPDRS level: 3\n');
    level=3;
elseif  peak > 300
    fprintf('UPDRS level: 4\n'); 
    level=4;                                 
end

% TIPOLOGIA DI TREMORE
if freq < 5.5
    fprintf('Tremor: RESTING\n');
end
if 5.5001 < freq && freq < 9
    fprintf('Tremor: POSTURAL\n');
end
if 9.0001 < freq
    fprintf('Tremor: KINETIC\n');
end

end