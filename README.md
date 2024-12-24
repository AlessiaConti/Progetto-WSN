# Analisi del tremore
Progetto per il corso di Wireless Sensor Network for IoT

## Obiettivo
Visto il rapido espandersi dell’uso in ambito sanitario di dispositivi wearable per il monitoraggio dei sintomi motori nella malattia di Parkinson, in questo progetto ci si è posti l’obiettivo di sviluppare un modello di classificazione capace di quantificare il livello di tremore di un soggetto, a partire dai dati acquisiti tramite sensori accelerometrici. Il modello si basa sulla correlazione con la scala UPDRS (Unified Parkinson's Disease Rating Scale) e confronta i risultati di un algoritmo basato su soglie statiche con quelli di un modello di Machine Learning addestrato utilizzando specifiche caratteristiche estratte dai segnali. Inoltre, include un classificatore binario che distingue tra stato di tremore e assenza di tremore.
La scala UPDRS è uno strumento comunemente utilizzato per valutare la gravità della malattia di Parkinson, con valori che vanno da 0 (assenza di tremore) a 4 (tremore grave).
I dati raccolti sono stati analizzati ed elaborati utilizzando MATLAB, attraverso operazioni di pre-elaborazione, estrazione delle features e sviluppo del modello di classificazione. Infine, i risultati ottenuti sono stati confrontati con quelli riportati in letteratura per verificare l’efficacia del sistema e trarre le conclusioni.

## Dataset
Il dataset utilizzato per sviluppare il progetto, reperibile sul sito [ieee-dataport](https://ieee-dataport.org/open-access/pd-biostamprc21-parkinsons-disease-accelerometry-dataset-five-wearable-sensor-study-0) ed etichettato dalla supervisione dei neurologi, è denominato “PD-BioStamp RC 21” e contiene dati derivanti da un sensore accelerometrico utilizzati per studiare il tremore e altri sintomi motori presenti sia in soggetti con malattia di Parkinson che in soggetti cosiddetti ‘di controllo’. Il dataset è formato da più documenti, in particolare il file denominato [Clinic_Data_PD_BioStampRCStudy.csv](0.Dataset/Clinic_DataPDBioStampRCStudy.csv) contiene tutte le informazioni relative ai soggetti considerati e include: l’identificativo di ogni singolo soggetto che costituisce il dataset, il sesso, lo status (cioè se si tratta di un soggetto parkinsoniano oppure di controllo), l’età, la tipologia di test cui è stato sottoposto (per esempio l’etichetta ‘3_17’ indica che si tratta di un test a riposo, la lettera definisce la posizione del sensore e la dicitura on/off si riferisce alla medicazione). Nella tabella viene riportato il valore UPDRS associato a ciascuna prova svolta, per ogni paziente.

## Preprocessing
Poiché l’obiettivo del nostro lavoro è quello di studiare solo il tremore a riposo sugli arti superiori, è stato necessario effettuare delle operazioni di pre-processing e filtraggio per estrarre dal dataset solo i dati utili per i nostri scopi [(1.Preprocessing)](1.Preprocessing).
- [x] Per prima cosa dal file Annot di ogni paziente sono stati estratti solo i dati relativi alle prove di nostro interesse, identificati dalle etichette "updrs_3_17a" (RUE - Right Upper Extremity) e "updrs_3_17b" (LUE - Left Upper Extremity), ovvero le colonne 5 e 6.
- [x] Dopodiché, a partire da questi dati, è stato possibile ricavare i valori di accelerazione corrispondenti; i file utilizzati per estrarre le accelerazioni di ogni paziente sono denominati “rh” (Right anterior forearm) e “lh” (Left anterior forearm).
- [x] A questo punto, i valori estratti sono stati associati a quelli della scala UPDRS presenti sulla tabella ClinicData.
Per realizzare queste operazioni di pre-processing è stato implementato uno script Matlab, il cui risultato finale è una tabella unica contenente le prove di ogni paziente con i relativi dati accelerometrici, la durata e il livello nella scala UPDRS.
- [x] Dopo le operazioni di pre-processing del dataset per ottenere i dati utili per il nostro scopo, abbiamo proseguito ricampionando e filtrando i segnali di accelerazione, utilizzando il padding.
- [x] Dopodiché si è passati al calcolo della funzione di autocorrelazione e della densità spettrale di potenza, necessaria per l’operazione di estrazione delle features

## Estrazione delle features
L'estrazione delle features è un passaggio fondamentale che serve a trasformare i dati in una rappresentazione più informativa e utile per l'addestramento dei modelli di Machine Learning. Le features sono state estratte a partire dalla trasformata di Fourier (FFT) del vettore accelerazione campionato e filtrato, ovvero la densità spettrale di potenza (PSD), che rappresenta la distribuzione della potenza di un segnale nelle diverse frequenze. Le features principali sono riportate di seguito: 
- **Peak**: il valore massimo della densità spettrale di potenza, cioè l’ampiezza del picco principale
- **Fo**: la frequenza associata al picco massimo, cioè la frequenza dominante, quella con il contenuto energetico maggiore nel segnale
- **F50**: la frequenza mediana sotto la quale è contenuto il 50% della potenza totale del segnale 
- **SF50**: la larghezza dello spettro attorno alla frequenza F50, cioè la banda di frequenze che contiene il 68% della potenza totale del segnale.
- **statistiche**: massimo e minimo, media, moda e mediana, deviazione standard, asimmetria dello spettro (skewness) e appiattimento (curtosi), ampiezza picco-picco.

L'estrazione delle features è stata eseguita su 12 pazienti, 21 prove e i dati sono stati raccolti in una tabella in formato CSV. [(2.Features)](2.Features) E' stata aggiunta anche una colonna per la classificazione binaria: partendo dal valore UPDRS reale, viene assegnata l’etichetta 0 in caso di non tremore, 1 per i livelli di tremore 1-2-3-4. Ciò potrebbe essere utile a causa della scarsità dei dati estratti: classificando in base a tremore/non tremore, l’accuratezza dovrebbe migliorare rispetto alla classificazione per livelli.

## Stima del livello UPDRS e normalizzazione
Il livello UPDRS viene assegnato in base all'intervallo della variabile peak:
```
peak < 5 → Livello 0 
5.001 < peak < 32 → Livello 1 
32.001 < peak < 200 → Livello 2 
200.001 < peak < 300 → Livello 3 
peak > 300.001 → Livello 4
```
L’obiettivo è il confronto tra questa stima basata su soglie statiche, rispetto al valore che si ottiene con il ML, utilizzando come input le features normalizzate [(3.Normalizzazione)](3.Normalizzazione). 

## Bilanciamento delle classi
Un problema riscontrato è che i dati sono pochi e il dataset è sbilanciato; la distribuzione di ogni classe, sia per classificazione binaria (0-1) che multiclasse (0-1-2-3-4), è la seguente:

Classificazione binaria:
Classe | Occorrenze
---- | ---- 
0 | 3 
1 | 18 

Classificazione multiclasse:
Classe | Occorrenze
---- | ----
0 | 3
1 | 9
2 | 5
3 | 4
4 | 0

Per bilanciare le classi è necessario effettuare data augmentation tramite la funzione [SMOTE](https://it.mathworks.com/matlabcentral/fileexchange/75168-oversampling-imbalanced-data-smote-related-algorithms) di MATLAB, che risolve questo problema generando nuovi esempi sintetici per le classi minoritarie. [(4.Bilanciamento classi)](4.Bilanciamento%20classi)

## Classification Learner
Il Classification Learner è un'applicazione di MATLAB che facilita l'addestramento di modelli di classificazione usando diversi algoritmi e set di features. Prima di utilizzare il Classification Learner, è necessario avere i dati organizzati in una tabella contenente le features e la colonna delle etichette di classe. Il Classification Learner supporta diversi algoritmi di classificazione, tra cui: Decision Tree (alberi decisionali), Support Vector Machine (SVM), K-Nearest Neighbors (KNN), Ensemble Methods, Logistic Regression, Naive Bayes. Dopo aver addestrato il modello si possono valutare le sue prestazioni visualizzando le metriche di Accuracy, Matrice di Confusione e Scatter Plot. [(5.Classification Learner)](5.Classification%20Learner)

## Risultati
- Dopo aver addestrato diversi modelli, si ha che per la Binary classification l’algoritmo di classificazione che fa previsioni più corrette è dato dal modello SVM (Support Vector Machine), in grado di classificare correttamente una percentuale maggiore di dati rispetto ad altri modelli testati, con un’accuracy che raggiunge il 95.65%.

![img](5.Classification%20Learner/Binary_95.png)

- Nel caso del Multilevel classification, dopo aver applicato la correlazione tra features per capire quali fossero le più utili da considerare e utilizzando il modello Tree, si è riuscito ad ottenere un’accuracy del 78.4%.

![img](5.Classification%20Learner/Multiclass_78.png)

## Autori
_Alessia Conti, Fulvio Michele Luigi Buono, Alessandro Polverari, Alex Voltattorni, Lorenzo Mozzoni, Raul Fratini_



