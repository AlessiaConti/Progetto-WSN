

function [newdata,visdata] = mySMOTE(data, minorityLabel, num2Add, options)

% Funzione di bilanciamento per classificazione binaria e multiclasse
%
% INPUT:
%  data                   -  tabella dei dati con features e target (classi da bilanciare)
% minorityLabel     - classe minoritaria che deve essere oversamplata
% num2Add           - numero di campioni sintetici da generare.
%
% OUTPUT:
%   newdata            - nuovo dataset bilanciato
%   visdata              - opzionale per il debugging

%%% REQUISITI !!
% 1. L'input 'data' dev'essere una tabella (table)
% 2. Le colonne delle features devono essere di tipo numerico 
% 3. La colonna target dev'essere di tipo stringa
% 4. Le etichette delle classi da bilanciare devono essere 
%     nell'ultima colonna della tabella di input.

%-----------------------------------------------------------------
% N (scalar numeric): Number of data to generate
% k (scalar integer): number of neighbors to consider

arguments
    data {mustBeTableWithClassname}
    minorityLabel (1,1) string 
    num2Add (1,1) double {mustBeNonnegative, mustBeInteger} = 0
    options.NumNeighbors (1,1) double {mustBePositive, mustBeInteger} = 5
    options.Standardize (1,1) logical = false;
end
numNeighbors = options.NumNeighbors;
if options.Standardize
    distance = 'seuclidean';
else
    distance = 'euclidean';
end
% If N is smaller than zero, do not oversample data
if  num2Add <= 0
    newdata = table;
    visdata = cell(1);
    return;
end
visdata = cell(num2Add,4);
% Optional output for visualization purpose only
% 1: y, 2: nnarray, 3: y2, 4: synthetic
% labels of whote dataset
labelsAll = string(data{:,end});
% feature dataset of the minority label
featuresMinority = data{labelsAll == minorityLabel,1:end-1};
% Number of minority data
NofMinorityData = size(featuresMinority,1);
% If the number of minority data is smaller than the requested number of new
% data set (num2Add), we randomly pick num2Add of minority data to be used to generate
% data.
if NofMinorityData >= num2Add
    idx = randperm(NofMinorityData,num2Add);
    featuresSubset = featuresMinority(idx,:);
    T1 = num2Add; % Number of data from minority dataset to be used
    T2 = 1; % Number of newdata from each minority dataset
else
    % Otherwise we use all minority data
    idx = randperm(NofMinorityData); % just to randamize
    featuresSubset = featuresMinority(idx,:);
    T1 = NofMinorityData; % Number of data from minority dataset to be used
    T2 = ceil(num2Add/NofMinorityData); % Number of newdata from each minority dataset
    % Note: doe to CEIL the total number of newdata may exceeds the
    % requested #, num2Add. Currently, the below has the routine to stop the process at num2Add.
end
% Array to save the synthesized features
newFeatures = zeros(num2Add,size(featuresMinority,2));
index = 1;
for ii=1:T1  % Number of data from minority dataset to be used
    y = featuresSubset(ii,:); % a minority data
    [nnarray, ~] = knnsearch(featuresMinority,y,'k',numNeighbors+1,...
        'Distance',distance, ...
        'SortIndices',true); % search for neighboring points
    % NOTE: this include self y, needs to omit y from nnarray
    nnarray = nnarray(2:end);
    for kk=1:T2 % Number of newdata from each minority dataset
        nn = datasample(nnarray, 1); % pick one from neighboring minority
        % Interpolation
        diff = featuresMinority(nn,:) - y; 
        synthetic = y + rand.*diff;
        newFeatures(index,:) = synthetic;
        
            
        visdata{index,1} = y;
        visdata{index,2} = featuresMinority(nnarray,:);
        visdata{index,3} = featuresMinority(nn,:);
        visdata{index,4} = synthetic;
        
        index = index + 1;
        % Once the tatal numerb of generated data reaches N
        % it ends the routine.
        
        if index > num2Add
            break;
        end
    end
end
% make newFeature to table data with the same variable names
tmp = array2table(newFeatures,'VariableNames',data.Properties.VariableNames(1:end-1));
% add label variable
newdata = addvars(tmp,repmat(minorityLabel,height(tmp),1),...
    'NewVariableNames',data.Properties.VariableNames(end));