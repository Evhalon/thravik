# Account/sync: architettura realizzata

Implementazione Swift 6 senza dipendenze app esterne. Tre provider password
selezionabili, login e backend pronti per collaudo. Schema cloud pubblicato;
collaudo client end-to-end e gate di produzione ancora necessari.
Profilo, Spaces, gruppi e pin si sincronizzano col vault sbloccato; le schede degli altri
Mac restano in lista e si aprono solo su richiesta. Gate di produzione sotto.

## Confini

```text
Redent → RedentUI → RedentKit
       → RedentSync → RedentKit
       → RedentVault → RedentKit
```

RedentKit contiene sessioni, errori tipizzati, porte auth/Keychain/sync e DTO
portabili. RedentSync contiene rete, PKCE, CryptoKit e coordinamento. RedentVault
contiene storage Keychain e SQLite. La composition root è Redent.
Nessun accesso WebKit nella sync, nessun accesso concreto Keychain nella UI/rete.

## Implementato

- Primo avvio: intro a tutto schermo con frasi successive e portale animato
  derivato dal logo, reveal testo con supporto
  Reduce Motion, ambient audio sintetizzato e segnali sonori disattivabili,
  nome/focus, funnel Space esistente, import opzionale tramite il selettore
  browser esistente (profili, cronologia, bookmark, password), login e setup/recovery del
  vault cifrato. Completamento locale persistito; setup interrotto dopo lo Space
  riprende dal login. Percorso locale disponibile anche con rete/auth assenti.
  Profilo opzionale nel catalogo cifrato, compatibile con sessioni/cataloghi
  precedenti. Undo delle schede conserva il profilo corrente.
- Settings → Testing consente di riavviare il setup reale con account/import
  effettivi e completamento locale azzerato. La voce demo resta separata.
  Import crea uno Space per profilo Chromium selezionato, riusa la mappatura
  nei retry dello stesso import e offre l’unione esplicita in uno Space esistente.
  Il blocco del workspace durante onboarding è interno al contenuto browser:
  non si propaga alla presentazione modale dell’import.
  I bookmark seguono lo Space; cronologia e password restano condivise.
  Gli Spaces interni ad Arc/Dia dentro un singolo profilo non sono ancora letti.
- Settings → Testing riavvia una demo dell'onboarding dall'intro. Profilo e
  Space sono temporanei; Google/email e vault sono simulati. La demo non modifica
  workspace, account, chiavi o completamento persistito e si può chiudere da
  qualsiasi step. Non ripropone il prompt per il browser predefinito.
- Modifiche workspace: debounce asincrono, errori gestiti e dati locali conservati.
  Primo collegamento legge tutte le pagine cloud prima di pubblicare il catalogo
  locale; risultati di uno store account precedente non vengono applicati.
- Account pane nelle Impostazioni: Google via browser di sistema, email OTP,
  password e recupero via codice email con conferma nuova password, refresh e
  logout. La sessione di recupero resta temporanea fino al salvataggio riuscito.
  Nessuna configurazione → account disabilitato.
- Google con verifier/state casuali, SHA256, callback validata e
  consumata una volta. Trasporto senza redirect, cookie e cache condivisi.
  La callback richiede state corrispondente; attesa registrata prima di aprire
  il browser, timeout cancellato senza interrompere tentativi successivi.
- Token nel Keychain; refresh rifiuta identità diversa. Logout elimina prima
  sessione locale, anche se la revoca remota non riesce.
  Fresh sessions restore without rewriting the Keychain token. Session deletion
  reaches the legacy Keychain when data-protection access lacks its entitlement;
  authentication failures and legacy deletion failures still propagate.
- Chiavi da 256 bit nel Keychain; AES-256-GCM, HKDF con domini vault/workspace,
  AAD per account/record/collection/epoch/schema. Recupero con segreto casuale
  da 256 bit e checksum; wrapping account-bound della root key.
- Cipher per mutazioni: ID, expected revision e tombstone duplicati nel payload
  autenticato, così il server non può alterarli senza fallire la verifica.
- SQLite WAL/FULL: outbox ciphertext durabile, idempotenza e isolamento account,
  replica corrente e cursore. Ack upload non avanza il cursore del pull.
- AuthenticatedSyncLocalStore verifica cifratura prima di applicare una pagina;
  commit della replica e cursore atomico. Pending locale rimane separato.
- SyncCoordinator actor: una run alla volta, pull prima di push, pagine/upload
  limitati a 100, cancellazione e conflitti espliciti. Nessun polling o timer.
  Il coordinatore richiede la porta AuthenticatedSyncStoring, non lo store raw.
- Membership device: chiavi X25519/Ed25519 nel Keychain, bootstrap del primo Mac,
  enroll in attesa, approvazione con root key avvolta (ECDH + HKDF + AES-GCM) e
  firma, oppure claim col codice di recupero. Il server conserva solo l'hash della
  credenziale device. Dopo il primo device, `sync_push` senza prova è rifiutato.
  Il client verifica la firma Ed25519 prima di applicare. Il server non verifica
  ancora la firma (manca pgsodium). Rotazione epoch ancora assente.
- Supabase RPC adapter con sessione Bearer, CAS, conferma receipt e pull ordinato.
- DTO workspace esclude tab temporanee, favicon, timeline, layout/selezione e
  URL locali; rimuove userinfo/query/fragment dagli URL HTTP(S).
- Sync workspace: catalogo cifrato condiviso (profilo, Spaces, gruppi, pin) e record
  `device_tabs` per Mac. Il merge non crea WKWebView per le schede remote.
  Un pin mancante torna ibernato. Una scheda di un altro Mac compare in
  Impostazioni → Account e si apre solo col pulsante Open. Stesso outbox e
  cursore delle password; un turno alla volta. Login da solo non pubblica:
  servono root key e device approvato.
- Backend Postgres e test SQL riproducibili: RLS, grant minimi, cursor seriale
  per account, transazioni, dedup, tombstone e limite iniziale del feed.

Limite client envelope: 180 KiB, per mantenere request JSON/base64 entro il
limite server di 256 KiB. Il batch coordinator è seriale e limitato; nessuna
compressione o upload massivo introdotto senza misura. Payload grandi richiedono
chunking/versione successiva, non aumento silenzioso del limite.

## Password: tre modalità

Impostazioni → Account → Password storage seleziona una modalità per volta.

- Locale: Keychain esistente, nessun account richiesto.
- Redent cloud: Keychain separato per account + outbox SQLite cifrata + Supabase.
  Journal cifrato precede scrittura Keychain; replay ripara interruzioni/crash.
  Sync all'avvio/foreground e debounce sugli accessi, pagine da 100, senza polling.
  Root key casuale locale: login da solo non sblocca un nuovo Mac. Creazione
  esplicita, conferma codice salvato, recupero account-bound su altro Mac.
  Envelope recovery immutabile sul server; CAS conserva varianti in conflitto.
  UI propone tenere locale oppure scartare locale e usare cloud.
- iCloud: record per password nel Keychain data-protection synchronizable,
  access group verificato dalla firma; nessun fallback a storage locale.
  Sincronizzazione gestita da macOS e dall'Apple Account. Non equivale a importare
  automaticamente il database Safari/Apple Passwords.

Cambio provider non copia implicitamente dati. Copia esplicita conserva origine;
password divergenti per stesso login interrompono importazione. Logout/cambio
account disattivano provider cloud, cancellano cache autofill e chiudono vault UI.
Modalità cloud salvata ma indisponibile restituisce errore, senza scrivere nel locale.

Root compone Keychain token/chiavi, Supabase recovery/transport, SQLite per
bundle/account, SyncMutationCipher, store autenticato e CloudCredentialStore.
Preferenza provider è l'unico dato password salvato in UserDefaults.

## Configurazione build

Solo URL e chiave pubblica entrano nel bundle. Mai service-role, client secret
Google, credenziali SMTP o access token amministrativi.

```sh
export REDENT_SUPABASE_URL='https://PROJECT.supabase.co'
export REDENT_SUPABASE_PUBLISHABLE_KEY='sb_publishable_PUBLIC_KEY'
make dev
```

scripts/configure-account.sh aggiunge Info.plist keys; SupabaseConfiguration
valida URL HTTPS e tipo chiave. Senza variabili, navigazione locale invariata.
La scheda Account è presente ma disabilitata.

Configurazione server necessaria:

- Google provider con OAuth client ID/secret sul server e callback Google
  https://PROJECT.supabase.co/auth/v1/callback.
- Redirect allowlist redent://account/callback e variante con query state
  limitata a quel percorso (non wildcard sull'intero schema).
- Email template con codice OTP (Token), non solo link; SMTP custom verificato.
- Migration backend e test isolamento, rate limit e quote prima del deploy.

La config locale Supabase include la allowlist. Usare chiave publishable moderna;
le chiavi JWT legacy anon/service-role vengono rifiutate dal client.

## Gate ancora necessari

- Rotazione epoch e verifica Ed25519 lato server (pgsodium). Approvazione da
  altro Mac e claim col codice di recupero sono implementati; la revoca non
  elimina l'ultimo device.
- Collegamento identità Google/email con verifica e gestione account switch.
- Merge bookmark, cronologia e TOTP. Spaces, gruppi, pin e lista schede remote
  sono integrati; la cancellazione di uno Space viaggia con gli id ritirati del
  catalogo, non con un record per entità.
- Prova reale password su due Mac, offline e account switch; misure prestazioni.
- Checkpoint/compattazione. La fondazione conserva il feed fino al cap di 10.000
  cambiamenti per account e poi blocca nuove scritture con quotaExceeded; non è retention definitiva.
- Quote/rate limiting operative, backup/restore, benchmark e audit indipendente.
- Google/email end-to-end con progetto reale e prova su due Mac.

Il client rifiuta pagine con firma assente o invalida dopo che esiste un device
approvato. Il server autentica la credenziale del device, non la firma Ed25519.
Senza rotazione epoch questa non è revoca crittografica. Un server ostile può
ancora omettere o riordinare dati già letti.

## Verifica

make verify controlla linee, layout, import, release build e tutta la suite Swift.
Test nuovi coprono OTP/PKCE, refresh account mismatch, errori senza segreti,
AES tamper/context/key, recovery, mutazioni alterate, persistenza/reopen outbox,
CAS, receipt errata, cursori e pagine non autenticate. SQL ha suite separata
backend/tests/run.sh; ambiente Supabase/Docker richiesto. Risultati effettivi
sono riportati nella consegna, non dedotti dalla presenza dei test.

Verifica 2 ottobre 2026: release build senza warning; limiti/layout/dependency
check puliti. Suite completa: 1.071 test, solo due test video preesistenti
falliscono (FloatingVideoPlaybackTests.controlsOriginalVideo e
FloatingVideoTests.overlayControlsOriginalVideo, tre assertion). Dopo fix firma
e warning fixture: 69 test mirati account/crypto/sync/password/router/autofill/
iCloud/passkey passano senza warning. SQL e concorrenza Postgres 17 passano.
Il gate `make verify` resta rosso per quei test Engine; nessun test saltato
nella verifica completa. Firma/profilo Apple reale e Supabase live non verificati.

## Regressione interazione import durante onboarding

Avviare il setup reale senza completarlo e aprire Import dal menu Library
(o dallo step import). Deselect all deve svuotare la selezione, un profilo deve
poter essere riselezionato, le caselle dei dati devono cambiare stato e Cancel
deve chiudere la finestra tornando al setup. Ripetere con il setup completato.
La verifica non richiede di leggere o salvare i dati del browser sorgente.

## Archivi password durante import

Un profilo rilevato tramite cronologia o bookmark può non avere `Login Data`
né `Login Data For Account`: questo caso produce zero password e non richiede
la chiave Safe Storage. Un archivio presente ma illeggibile resta un errore;
la UI conserva i dati importati con successo e propone un tentativo separato.
Gli errori SQLite durante la lettura, anche dopo alcune righe, vengono propagati.

## Scelta browser al termine del setup

Il setup termina con una scelta dedicata del browser predefinito. La richiesta
a macOS parte solo con “Use Thravik”; le altre scelte terminano senza cambiare
associazione. “Keep current” silenzia le offerte future, “Decide later” registra
solo l'offerta della versione corrente. Il completamento non apre una seconda
finestra di proposta. In demo nessuna scelta consulta macOS o salva preferenze.

L'esito dell'import sostituisce la lista dei profili nella stessa finestra.
Conteggi e problemi restano visibili senza scorrere la lista; il ritorno alle
opzioni conserva selezioni e destinazioni per riprovare. Un nuovo tentativo
mostra il proprio riepilogo al termine.

Lo step import dell'onboarding mostra l'ultimo riepilogo completato anche dopo
la chiusura della finestra import e dopo riavvio. Sono salvati solo conteggi,
nomi dei profili selezionati e messaggio di esito, senza URL o credenziali.
Il riepilogo descrive un singolo tentativo, non un totale cumulativo; un import
parziale resta segnalato come tale. La demo usa un esempio in memoria e non
sostituisce il riepilogo reale. Gli import antecedenti alla registrazione del
riepilogo non hanno conteggi storici ricostruibili automaticamente.

## Identità account e sidebar

La sessione Keychain conserva email e metodo dell'accesso corrente (Google o
email); il refresh mantiene il metodo noto. I dati legacy restano decodificabili
e un aggiornamento opportunistico prova a recuperare email mancante senza
scollegare la sessione in caso di errore. Metadati ambigui non diventano un
metodo inventato. Il logout dalle impostazioni richiede conferma cancellabile.

La riga degli Spaces scorre orizzontalmente quando supera la larghezza della
sidebar, con contatore delle pagine che segue lo scroll e gestione Spaces sempre
raggiungibile. Lo scorrimento della riga non cambia lo Space selezionato.
Il pin vuoto e lo stato senza tab restano visibili nello Space selezionato.
L'import dei profili riguarda bookmark, cronologia e password; non ricostruisce
le schede fissate del browser sorgente. Le tab fissate locali restano nel loro
Space durante il primo merge con il catalogo account.
