
% Questa funzione viene utilizzata in mySMOTE 
% 
% Serve a garantire che l'input passato a mySMOTE soddisfi i seguenti requisiti:
% 1. Deve essere una tabella (table).
% 2. Le colonne delle features devono essere numeriche.
% 3. L'ultima colonna (il target) deve essere di tipo stringa.

% ----------------------------------------------

function mustBeTableWithClassname(arg)
    features = arg{:,1:end-1};
    class = arg{:,end};
    if ~isnumeric(features)
        error(['not numeri features'])
    end
    if ~isstring(class)
        error(['not a string classname'])
    end
end


