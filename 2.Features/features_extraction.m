



function [peak, freq, F50, SF50, features_extr] = features_extraction(ax, ay, az)

% Funzione per estrarre le features dai dati di accelerazione
%
% INPUT:
%   ax, ay, az     - Vettori di accelerazione lungo gli assi X, Y, Z
%
% OUTPUT:
%   peak            - Picco della densità spettrale di potenza
%   freq              - Frequenza associata al picco massimo
%   F50               - Frequenza mediana della densità spettrale di potenza
%   SF50             - Larghezza dello spettro attorno alla frequenza mediana
% features_extr  - Vettore con features aggiuntive

% RICAMPIONAMENTO
fs=30;
fc=31.25;
P = round(fs * 1000);
Q = round(fc * 1000);

% RMS originale
for i = 1 : length(ax)
    acc0(i) =  (sqrt((ax(i))^2+(ay(i))^2+(az(i))^2));
end

% PADDING
acc0pad= [repmat(acc0(1), 1, 30), acc0, repmat(acc0(end), 1, 30)];
acc0pad_resampled = resample(acc0pad, P, Q);
acc0nopad= acc0pad_resampled(30:end-29);

%conversione
acc=acc0nopad * 9.80665;

% FILTRAGGIO
n=3;
Wn= [3 6] / (fs/2);
ftype='bandpass';
[b,a] = butter(n,Wn,ftype);
filtrato=filtfilt(b,a,acc);


% AUTOCORRELAZIONE
n=length(filtrato);
M=round(n/5);
autocorr=zeros(2*M+1,1);
for m=0:M
    somma=0;
    for j=0:(n-1-m)
        somma=somma+filtrato(j+1)*filtrato(m+j+1);
    end
    autocorr(M+1+m)=somma/(n-m);
end
for i=1:M
    autocorr(i)=autocorr(2*M+2-i);
end

% DENSITA' SPETTRALE DI POTENZA
S=fft(autocorr,(2*M+1));
f_FT=(0: fs/(2*M+1) : fs -fs /(2*M+1));

S=abs(  S(1:(M+1))  );
f_FT=f_FT(1:(M+1));


%%% ESTRAZIONE FEATURES %%%
fprintf('\n> Features estratte:\n');

% feature (1) e (2)
% calcolo picco e Fo
peak = 0;
[peak, idx] = max(S);  %% <- feature da salvare
freq = f_FT(idx);  %% <- feature da salvare

fprintf('Peak: %f\n', peak);  
fprintf('F0: %f\n', freq);  

% feature (3)
% calcolo F50
totP=0;
for i=1:length(S)
    p(i)=S(i)*(fs/n);
    totP=totP+p(i);
end
F=totP/2;
potT=0;
i=0;
while potT<F
    i=i+1;
    pot(i)=S(i)*(fs/n);
    potT=potT+pot(i);
    freq50(i)=f_FT(i);
    asse(i)=S(i);
end
F50=max(freq50); %% <- feature da salvare

fprintf('F50: %f\n', F50);


% feature (4)
% calcolo SF50
per68=(totP/100)*68;
per=0;
j=i+1;
SF50=0;
while per<per68
    i=i+1;
    j=j-1;
    per=per+S(i)*(fs/n)+S(j)*(fs/n);
    SF50=f_FT(i)-abs(F50);
end
A=0.01;
if 500>max(S)>100
    A=0.1;
elseif max(S)>500
    A=1;
end
fprintf('SF50: %f\n', SF50); %% <- feature da salvare


%%% ESTRAZIONE FEATURES AGGIUNTIVE %%%

% Calcola la trasformata di Fourier
FFT=fft(filtrato);
S = abs(FFT);

% Calcola le features sulla trasformata
features_extr(:,1) = max(S); % Valore massimo dello spettro
features_extr(:,2) = min(S); % Valore minimo dello spettro
features_extr(:,3) = mean(S);  % Media dello spettro
features_extr(:,4)= std(S); % Deviazione standard dello spettro
features_extr(:,5) = skewness(S); % Asimmetria dello spettro
features_extr(:,6) = kurtosis(S); % Curtosi dello spettro
features_extr(:,7) = median(abs(S - median(S))); % Mediana degli scostamenti assoluti dallo spettro medio
features_extr(:,8)=peak2peak(S); % Ampiezza picco-picco dello spettro
features_extr(:,9)=mode(S);  % Moda dello spettro
features_extr(:,10)=max(findpeaks(S)); % Valore massimo dei picchi dello spettro



end