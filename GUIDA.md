# Guida step-by-step

La seguente guida spiega come eseguire un backup/snapshot tramite l'utility kelvim.

## 1. Individuare la VM
Per individuare la VM di cui eseguire il backup usare cockpit aprendo l'indirizzo `https://<ip del server>:9090` ed eseguire il login.

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/ed5d0f33-7143-454c-aa3d-f522c2b31891">

Individuare la VM visitano la pagina "Virtual machines".

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/bed9cfc3-1340-478a-95fe-cbba125d1ed5">

Aprire la sotto-pagina specifica per la VM, per esempio la VM con ID `039541a9-c976-4ab1-9ef0-2f0d09290612`:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/5b1d37cd-6833-40dc-bfdf-b8068fbf1ba5">

Copiare l'ID della VM e aprire un terminale sull'host, per esempio la sezione "Terminal" del Cockpit:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/1ffc6584-e8cc-4a83-9bf4-1848b19cb6ad">

## 2. Eseguire il backup/snapshot
Inserire il seguente comando nel terminale:

```bash
kelvim-snapshot-creator.sh --domain <ID della VM> --external
```
L'output sarà simile a quello seguente:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/706009bf-d728-4e69-b95d-ae0a937ed80a">

La linea di output seguente indica la destinazione del backup:

```
Starting backup of disk 334ac893d0824efaaee8baef379d41b5 towards /mnt/elemento-vault/snaps/<ID volume>.elsnaps/<data>
```

## 3. Verificare lo stato dei backup e degli snapshot
Utilizzando il percorso di destinazione indicato nell'output del comando precedente, inserire il seguente comando nel terminale:

```bash
kelvim-snapshot-lister.sh --source /mnt/elemento-vault/snaps/<ID volume>.elsnaps/<data>
```
L'output elencherà i backup e gli snapshot disponibili, per esempio:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/bc29f6ae-a447-47b7-8b5d-8ad28a4ce2f0">

Saranno elencati tutti gli istanti salvati. Il primo backup del giorno è sempre un backup completo, quelli seguenti sono backup incrementali rispetto al primo.

## 4. Ricostruire il disco di una VM
Il comando per ripristinare uno stato precedente del disco della VM è:

```bash
kelvim-snapshot-restorer.sh --source /mnt/elemento-vault/snaps/<ID volume>.elsnaps/<data> --target <destinazione> --until <ID dello snapshot terminale>
```

Nell'esempio precedente, volendo ripristinare lo stato della VM al backup `virtnbdbackup.2`, occorrerà utilizzare il comando:

```bash
kelvim-snapshot-restorer.sh --source /mnt/elemento-vault/snaps/334ac893d0824efaaee8baef379d41b5.elsnaps/240927 --target /tmp/restored --until virtnbdbackup.2
```

Nel percorso `/tmp/restored` verrà rigenerato un file immagine `raw` contenente tutti i dati della VM fino al backup `virtnbdbackup.2`.

**N.B. la nuove immagine non viene sostituita automaticamente a quella attualmente usata dalla VM. La sovrascrittura deve essere eseguita a mano.**

## 5. Sostituire alla VM il disco attuale con quello ripristinato
Tornare sulla pagina Cockpit della VM (sezione "Virtual machines") e spegnere la VM tramite l'apposito pulsante:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/94954103-6c5c-4e28-8728-389f73de32d6">

Scorrere fino alla sezione "Disks":

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/5fb85518-790b-4204-9ebb-80abcda866d5">

Rimuovere il disco attuale della VM selezionando "Remove" **e non "Remove and delete file"**:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/b05afa86-de6a-4a43-a1f9-40ea9eea8c79">
<img width="1029" alt="image" src="https://github.com/user-attachments/assets/7e1bd21c-9117-4fcb-9acd-15b40776ca49">

Aggiungere il disco ripristinato:

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/acd447e0-15bc-402c-97f7-081a3158609c">
<img width="1029" alt="image" src="https://github.com/user-attachments/assets/48f27cc9-20c5-4555-93ab-60a58c1c9539">
<img width="1029" alt="image" src="https://github.com/user-attachments/assets/f248e012-34de-4f4a-88fa-69d077e091f4">
<img width="1029" alt="image" src="https://github.com/user-attachments/assets/0d665dd9-b5d8-498c-b9cd-d4cf2f2d61bd">
<img width="1029" alt="image" src="https://github.com/user-attachments/assets/a631ae8a-32a8-4082-ab17-2478c91a864f">

Avviare la VM tramite il bottone "Run".

<img width="1029" alt="image" src="https://github.com/user-attachments/assets/f78ec4b1-2d16-498e-8d5a-a206b9b053c9">

Verificare che il rirpristino abbia avuto successo dall'interno della VM.



