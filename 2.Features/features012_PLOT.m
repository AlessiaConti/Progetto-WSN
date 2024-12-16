clc; clear all; close all;

% caricamento file con finestre già ritagliate e sottocampionate
data=readtable('combined_patient_data.csv'); % tabella completa

% TEST di estrazione features SU SINGOLO PAZIENTE (012)
% SOLO PROVA 1 


%%  CAMPIONAMENTO
% da 31.25 a 30 Hz

% si estraggono le colonne 6-7-8 della tabella (le accelerazioni)
% per la prova 1 prendo solo righe da 163 a 228
ax=data{163:228,6}; % accel x
ay=data{163:228,7}; % accel y
az=data{163:228,8}; % accel z

fs=30; %frequenza di lavoro
fc=31.25; %frequenza di campionamento originale

P = round(fs * 1000); % Fattore di upsampling
Q = round(fc * 1000); % Fattore di downsampling
% round()->per evitare valori decimali

% modulo accelerazione originale
for i = 1 : length(ax)
    acc0(i) =  (sqrt((ax(i))^2+(ay(i))^2+(az(i))^2));
end

% PADDING
acc0pad= [repmat(acc0(1), 1, 30), acc0, repmat(acc0(end), 1, 30)];
acc0pad_resampled = resample(acc0pad, P, Q); 
acc0nopad= acc0pad_resampled(30:end-29);

% plot PADDING
figure(1);
subplot(2,1,1);
plot( acc0pad, 'r');
title('Padding');
subplot(2,1,2);
plot( acc0pad_resampled, 'r');
title('Ricampionato con padding');


% conversione da g a m/s^2
acc=acc0nopad*9.80665;


%%  FILTRAGGIO

% FILTRO Butterworth passa-banda
n=3; % ordine del filtro
Wn= [3 6] / (fs/2); % frequenze cutoff per resting tremor
ftype='bandpass'; 
[b,a] = butter(n,Wn,ftype);
filtrato=filtfilt(b,a,acc); % filtraggio FIR

figure(2);

% plot RMS originale
subplot(2,1,1); 
t1=0: 1/fc : (length(acc0)-1)/fc; % fc freq iniziale
plot(t1, acc0);
title('Originale ');

% plot RICAMPIONATO
subplot(2,1,2);
t2=0: 1/fs : (length(acc)-1)/fs;
plot(t2, acc);
title('Ricampionato');

% plot FILTRATO
figure(3);
plot(filtrato);
title('Filtrato');

%%  AUTOCORRELAZIONE

% calcolo TRASFORMATA
FFT=fft(filtrato);
FFT=fftshift(FFT);

ts = 1 / fs;
Tmax=ts*(length(filtrato)-1); % lunghezza del segnale in secondi:

F1=-fs/2 : 1/Tmax : fs/2; % costruzione asse delle frequenze

% % plot
% figure(4)
% plot(F1,FFT);
% title('Trasformata di Fourier segnale filtrato');


% stima della funzione di AUTOCORRELAZIONE
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
    autocorr(i)=autocorr(2*M+2-i);  %per parita' segnale diventano 2M+1 campioni
end

% Trasf di Fourier dell'autocorrelazione = Densità spettrale di potenza
S=fft(autocorr,(2*M+1)); % densità spettrale di pot
f_FT=(0:fs/(2*M+1):fs-fs/(2*M+1)); % asse delle frequenze

S=S(1:(M+1));             % elimino la seconda meta' delle stime (per simmetria)
f_FT=f_FT(1:(M+1));   % elimino la seconda meta' dei campioni
S=abs(S);

% plot
figure(5)
plot(f_FT,S)
axis([0, 15, 0, max(abs(S))])
xlabel('Frequenza(Hz)')
title('Densità spettrale di potenza da autocorrelazione')


%% ESTRAZIONE FEATURES
clc;
fprintf('Features estratte:\n');

% feature (1) e (2)
% calcolo freq fondamentale Fo e picco della densità di pot
peak = 0;
for i = 1 : length(S)
    if S(i) > peak
        peak = S(i); %% <- feature da salvare
        freq = f_FT(i); %% <- feature da salvare
    end
    continue
end
freqABC= num2str (freq);
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
asse1 = max(asse);

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


% FEATURES estratte da salvare nel CSV:
% (1) peak: val max della densità spettrale di potenza (ampiezza del picco)
% (2) Fo: freq associata al picco massimo (freq fondamentale del segnale)
% (3) F50: frequenza mediana della densità spettrale di potenza
% cioè frequenza sotto la quale è contenuto il 50% della potenza totale del segnale
% (4) SF50: larghezza dello spettro attorno alla frequenza mediana



%%  STIMA UPDRS

fprintf('\nCorrelazione con scala UPDRS:\n');
level=0; % inizializzo la variabile in cui salverò il livello UPDRS

%Calcolo correlazione UPDRS e stampo a video
if peak < 5
    fprintf('UPDRS level: 0\n');
    level=0;
elseif 5.001 < peak && peak < 32
    fprintf('UPDRS level: 1\n');
    level=1;
elseif 32.001 < peak && peak < 200
    fprintf('UPDRS level: 2\n');
    level=2;
elseif 200.001 < peak && peak < 300
    fprintf('UPDRS level: 3\n');
    level=3;
elseif  peak > 300.001
    fprintf('UPDRS level: 4\n'); %% <- da salvare NON come feature
    level=4;                                 % ma per il confronto con il ML
end

% NB: Il livello UPDRS stimata con le soglie NON è la vostra label
% La label è quella presente nel dataset BIOStamp.
% Questa vi servirà per confrontare i valori ottenuti con il ML rispetto
% all'uso di soglie statiche


%determino e stampo a video la tipologia di tremore
if freq < 5.5
    fprintf('Tremor: RESTING\n');
end
if 5.5001 < freq && freq < 9
    fprintf('Tremor: POSTURAL\n');
end
if 9.0001 < freq
    fprintf('Tremor: KINETIC\n');
end


%%  CREAZIONE FILE CSV

% Definisco le etichette della tabella
Picco=peak;
Fo=freq;
Label_UPDRS = test06{1,11};
ID_Paziente = test06{1,1};
Trial_Paziente = test06{1,2};
Stima_UPDRS= level;

% Creo la tabella
T = table(Picco, Fo, F50, SF50, Label_UPDRS, ID_Paziente, Trial_Paziente, Stima_UPDRS);

% Scrivo la tabella su un file CSV
writetable(T, 'Features012.csv');

fprintf('\nFile CSV salvato come "Features012.csv"\n');



%% Affidabilità del risultato

%XY=0:A:max(S);
dx=F50+SF50;
sx=F50-SF50;

figure(6)
plot(f_FT,S);%,F50,XY,'m',dx,XY,'g',sx,XY,'g');

x3 = [F50 F50];
y3 = [0 max(S)];
line (x3,y3, 'Color','m');

x1 = [dx dx];
y1 = [0 max(S)];
line(x1,y1,'Color','g');

x2 = [sx sx];
y2 = [0 max(S)];
line(x2,y2,'Color','g');

axis([0 15 0 max(S)])
title('Densità spettrale di potenza')
xlabel('Frequency (Hz)','color','r')
ylabel('S(f)','color','r')

legend('S ','F50','SF50')



