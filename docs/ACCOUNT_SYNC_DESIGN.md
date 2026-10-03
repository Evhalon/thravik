# Account e sincronizzazione cifrata — proposta implementabile

Stato: login, tre provider password, sync E2EE e recupero implementati nel codice.
Vedere ACCOUNT_SYNC_ARCHITECTURE.md per stato effettivo e gate. Schema cloud
pubblicato; le sezioni seguenti descrivono anche funzionalità ancora pianificate.
Data verifica provider: 2 ottobre 2026. Ambito autorizzato: Swift/macOS e backend.

## Scelta

Supabase gestisce identità, API e PostgreSQL; Brevo invia email transazionali.
Google OAuth e email con codice monouso sono i due accessi iniziali.
L'app resta utilizzabile senza account e senza rete. La sync è opzionale.
Nessun server applicativo dedicato nella prima versione.

Le alternative valutate sono Firebase Auth + Firestore e backend self-hosted.
Firebase è valido, ma Postgres facilita transazioni, controllo delle revisioni,
vincoli e portabilità. Il self-hosting aggiunge patch, backup e reperibilità:
non è la scelta iniziale per minimizzare lavoro operativo.

## Esperienza utente

1. Impostazioni → Account e sincronizzazione.
2. «Continua con Google» oppure email → codice ricevuto → conferma.
3. Primo dispositivo: crea vault cifrato, mostra codice di recupero e richiede
   conferma del suo salvataggio prima di completare l'attivazione.
4. Nuovo dispositivo: login, poi approvazione da Mac già autorizzato oppure
   inserimento del codice di recupero. Il login da solo non decifra il vault.
5. Ripristina Spaces, gruppi, pin e password; mostra «Schede degli altri
   dispositivi» con azione per aprirle. Non avvia tutte le pagine in background.
6. Schermata account: ultimo successo, modifiche in attesa, errore recuperabile,
   dispositivi, revoca, esportazione cifrata, eliminazione account.

Google usa sessione di autenticazione di sistema e authorization code + PKCE,
non una pagina Google dentro WKWebView. Verifica callback e challenge;
annulla richieste scadute e impedisce scambi di sessione fra tentativi.
Email usa OTP per evitare dipendenze dal browser che apre un magic link.
Gli accessi Google/email devono poter essere collegati alla stessa identità
con verifica di possesso; non unire vault sulla sola uguaglianza dell'email.

## Che cosa sincronizziamo

| Categoria | Comportamento |
|---|---|
| Password | Vault E2EE; destinazione locale Keychain |
| TOTP | Facoltativo, consenso dedicato; seed nel Keychain |
| Spaces | Nome, colore, icona, ordine e identità stabile condivisi |
| Gruppi e pin | Struttura condivisa; riferimenti con UUID stabili |
| Schede normali | Sessioni per dispositivo; apertura/importazione esplicita |
| Preferiti | Condivisi; cartelle e ordine inclusi |
| Impostazioni | Allowlist di preferenze portabili |
| Cronologia | Opt-in separato, retention e cancellazione sincronizzate |
| Schede temporanee/private | Sempre escluse |
| Cookie/sessioni dei siti | Esclusi dalla prima versione |
| Passkey | Nessuna esportazione di chiavi private gestite dal sistema |
| Download, file, cache, favicon, screenshot | Esclusi dalla sync iniziale |
| Permessi camera/microfono, percorsi, finestre | Locali al dispositivo |

Ripristinare URL e password non ripristina automaticamente il login nei siti:
cookie, token legati al dispositivo, MFA e stato JavaScript non sono portabili
in modo generale. L'autofill conserva il controllo dell'utente e non invia form.
Redent oggi supporta macOS 26; questa funzione abilita altri Mac compatibili.
Windows/Linux richiedono un client separato: il protocollo non deve impedirlo.

## Cifratura e chiavi

Usare primitive di sistema CryptoKit; nessun algoritmo crittografico inventato.
AES-256-GCM cifra ogni record con nonce casuale nuovo per ogni cifratura.
Authenticated Additional Data lega ciphertext a protocol version, account ID,
record ID, collection, key epoch e versione del payload.

Una root key casuale da 256 bit è generata sul primo dispositivo. HKDF-SHA256
con separazione dei domini deriva chiavi distinte per vault e workspace.
La root key e le chiavi private dei dispositivi restano nel Keychain locale;
i refresh token hanno una voce Keychain separata. Nessuna chiave segreta nel
bundle, nei log, in UserDefaults o nelle configurazioni versionate.

Il codice di recupero contiene 256 bit casuali codificati per trascrizione con
checksum. Una chiave derivata da quel segreto protegge la root key sul server.
Non è una password scelta dall'utente e non richiede una KDF per password.
Un'eventuale futura master password richiede una KDF memory-hard revisionata
(es. Argon2id), con parametri misurati e implementazione affidabile.

Ogni dispositivo genera chiavi Curve25519 di accordo e firma. Per approvarne
uno nuovo, il dispositivo esistente verifica una fingerprint/codice tramite
canale indipendente e invia un envelope della root key protetto da accordo
ECDH + HKDF + AES-GCM, legato a destinatario e richiesta con scadenza.
Le chiavi pubbliche pubblicate dal server non sono fidate senza verifica.

Le operazioni vengono firmate dal dispositivo autorizzato e verificate prima
di applicarle localmente. La cifratura non impedisce a chi conosce la root key
di creare ciphertext: le firme identificano l'autore e aiutano la revoca.
Il protocollo di membership e rotazione deve essere specificato e testato
prima della sync del vault, non aggiunto dopo la pubblicazione.

Revoca: blocco server immediato delle operazioni del dispositivo, invalidazione
sessioni e nuova key epoch distribuita ai dispositivi rimasti. I dati futuri
usano nuove chiavi; re-encryption del materiale corrente procede in background.
Una revoca non cancella dati già letti o chiavi già copiate da un dispositivo.

Reset dell'email o recupero dell'account non recupera le chiavi E2EE. Senza
codice di recupero né dispositivo autorizzato, i dati cloud non sono decifrabili.
Il client conserva stato verificato e checkpoint per rilevare replay/rollback
noti; un nuovo dispositivo non può dimostrare da solo che un server ostile non
abbia omesso dati. Non promettere protezione assoluta contro rollback server.

Il server vede identità account, dispositivi, dimensioni, tempi e traffico.
Non vede password, seed, URL, titoli, nomi degli Spaces o cronologia decifrati.
E2EE non protegge un Mac compromesso mentre il vault è sbloccato.

## Modello dati cloud

Postgres conserva ciphertext e metadati minimi, non tabelle di password chiare.

| Tabella | Scopo |
|---|---|
| sync_accounts | Versione protocollo e key epoch |
| sync_devices | Chiavi pubbliche, stato membership, revoca |
| sync_key_envelopes | Root key cifrata per dispositivo/recupero |
| sync_records | Stato corrente per collection e record UUID |
| sync_changes | Feed di cambiamenti ordinato per account |
| sync_mutations | Deduplicazione idempotente e risultato della mutation |
| sync_checkpoints | Compattazione del feed e snapshot cifrati |

Ogni riga ha owner_id; indici partono da owner_id e chiave di ricerca.
RLS obbligatoria, privilegi minimi, nessun accesso anonimo; owner_id deriva
dalla sessione verificata, mai da un parametro considerato fidato.
La service-role key resta nei soli strumenti amministrativi/server.

Le scritture passano da una RPC transazionale: autentica utente/dispositivo,
controlla limiti, verifica expected revision, aggiorna record, feed e risultato
idempotente nella stessa transazione. Gli accessi diretti che aggirano questi
controlli sono revocati. Errori hanno codici stabili e nessun contenuto sensibile.

Il cursore è monotono per account con allocazione serializzata fino al commit:
una sequence globale da sola può perdere cambiamenti se i commit arrivano fuori
ordine. Il pull è paginato; un cursore troppo vecchio richiede snapshot completo.
Limiti server per payload, batch, frequenza, dispositivi e storage per account;
RLS protegge l'isolamento ma non costituisce una quota anti-abuso.

## Sync, conflitti e performance

Il percorso critico resta locale: salvataggio locale + outbox persistente.
Nessuna navigazione aspetta una risposta cloud. Parsing, Keychain, crypto e
rete lavorano fuori dal MainActor. Un solo coordinatore per account/processo.

L'outbox su disco contiene solo envelope cifrati e metadati non sensibili.
Per i segreti, Keychain e SQLite non offrono una transazione congiunta:
serve journal di intenti cifrato, recovery e riconciliazione dopo crash.
Una scrittura locale non può andare persa fra update Keychain e accodamento.

Coalescing di modifiche ripetute; batch iniziale massimo 100 record / 256 KiB,
debounce iniziale 1 secondo, da tarare con misure. Upload di cambiamenti,
non dell'intero BrowserSession a ogni navigazione. Retry esponenziale con jitter,
cancellazione su logout/cambio account e rispetto di Retry-After.

Pull all'avvio, ritorno in foreground e riconnessione. Una connessione Realtime
condivisa, quando abilitata, segnala invalidazione: la fonte di verità è il feed
persistente. Nessun timer che interroga il backend o risveglia WKWebView.

Le sessioni di schede sono per dispositivo: chiudere una scheda sul Mac A
non chiude quella sul Mac B. Pin e struttura Spaces sono condivisi.
Conflitti sui segreti conservano entrambe le varianti e richiedono risoluzione;
nessuna password viene sovrascritta silenziosamente. Mutazioni strutturali usano
revisioni, merge per entità e riparazione esplicita dei riferimenti orfani.

Le cancellazioni sono tombstone. Un dispositivo offline con cursore scaduto
riparte dal checkpoint e non ripubblica come nuovi elementi cancellati.
Retention e compattazione hanno limiti espliciti; non conservare un feed eterno.
Eliminazione della cronologia crea tombstone anche per dispositivi offline.

Obiettivi iniziali, non risultati misurati: zero WKWebView creati dalla sync,
nessuna attività di rete a sync disattivata, nessun blocco percepibile durante
navigazione. Benchmark su 1.000 record, poi 10.000, rete lenta e disconnessa;
registrare byte trasferiti, latenza p50/p95, memoria e tempo sul MainActor.

## Integrazione con il codice attuale

La roadmap è storica: il checkout attuale contiene già Spaces, gruppi,
Container derivato dallo Space e finestre separate. Riutilizzare questi modelli.

- RedentKit/Features/Account e Sync: DTO, errori, porte e merge deterministico.
- RedentVault: Keychain token/chiavi e outbox SQLite cifrata; riuso adapter esistenti.
- Adapter cloud in un target RedentSync: Foundation networking e CryptoKit;
  dipende da RedentKit, mai da RedentUI/RedentEngine. Nessun SDK Google necessario.
- RedentUI: account view/model e stato sync attraverso porte iniettate.
- Redent/Application/AppContainer: composizione e unico coordinatore condiviso.

Riutilizzare CredentialStoring, TOTPAccountStoring, BookmarkStoring,
BrowserSession e SessionStoring. La sync non serializza direttamente l'intero
TabSnapshot: DTO allowlist esclude favicon, timeline privata e dati temporanei.
Container mantiene identità derivata dallo Space; nessuna copia di WebKit store.
Le chiavi e l'outbox sono isolate anche fra bundle release/debug.

Separare profilo locale preesistente da profilo dell'account. Primo collegamento
propone importazione esplicita; cambio account non mescola password o Spaces.
Logout elimina token e disattiva sync; l'utente sceglie se conservare copia locale
protetta. Eliminazione account richiede riautenticazione e pulizia cloud/locale
con stato verificabile, incluse policy di retention dei backup.

## Gratis iniziale e limiti

Supabase Free: 50.000 MAU, 500 MB DB, 5 GB egress, 1 GB file storage,
2 progetti attivi; pausa dopo una settimana di inattività. Backup automatici
non inclusi. Pro parte da 25 USD/mese; prezzi e quote vanno ricontrollati al deploy.

Brevo Free: 300 email/giorno. SMTP personalizzato obbligatorio per usare
email con utenti reali: quello incluso da Supabase è destinato a test,
limitato a indirizzi autorizzati e attualmente 2 invii/ora.

Il dominio mittente e la sua verifica DNS possono essere necessari per
consegna affidabile. Se non esiste un dominio, il suo acquisto è un costo
separato: non promettere produzione professionale a costo assolutamente zero.

Esempio di dimensionamento, non capacità garantita: 2.000 utenti × 100 KiB
cifrati = circa 195 MiB di soli payload. Indici, identità, versioni, outbox
cloud e feed aumentano occupazione. Potremmo pagare molto prima di 50.000 MAU.
Backup esportati cifrati e restore testati sono necessari; la disponibilità
senza SLA del piano Free non è equivalente a produzione ad alta affidabilità.

## Consegna e gate

1. Account: Google PKCE, email OTP, collegamento identità, refresh Keychain,
   schermata nativa, cancel/logout; nessuna sync dei segreti in questo gate.
2. Fondazione E2EE: recovery, approvazione device, membership firmata, revoca,
   rotazione, envelope versionato e test di manomissione/replay.
3. Backend: migration SQL, RLS/RPC, quote, feed/cursori, test isolamento con
   due utenti, backup e prova di restore, configurazione riproducibile.
4. Sync workspace/preferiti: outbox/recovery, delta, offline, conflitti,
   cancellazione, importazione su secondo Mac e nessun risveglio delle schede.
5. Vault: journal crash-safe, password/TOTP, conflitti visibili, account switch,
   revoca in presenza di device offline e recupero su installazione pulita.
6. Hardening: limiti, carico, accessibilità, report benchmark e test end-to-end.

Per ogni gate: make verify, Swift 6 senza warning e limiti AGENTS.md.
Test non solo round-trip: payload modificato, account/ID/AAD sbagliati, nonce,
chiave errata, retry duplicate, commit fuori ordine, cursore scaduto,
logout durante refresh, perdita rete, crash tra commit, offline delete e
Google/email collegati senza fusione di account estranei.
La sicurezza assoluta non è certificabile da test: vault pubblico richiede
anche revisione indipendente del protocollo e dell'implementazione.

## Ripartizione operativa

L'agente realizza codice app, schema SQL, test, configurazione/script backend,
email, callback, migrazioni, packaging e documentazione; con accesso autorizzato
configura i servizi e verifica login/sync su due installazioni.

Il proprietario crea account Supabase, Google Cloud e Brevo e concede accesso
tramite sessioni amministrative autorizzate. Servono eventuale controllo DNS,
verifiche del provider, consenso/branding Google e firma Apple per distribuzione;
interazioni personali o verifiche di proprietà non sono sostituibili dal codice.
Non inviare password, chiavi service-role o token amministrativi nella chat.
Se manca accesso amministrativo, fornire strumenti/configurazioni pronti ma
non dichiarare il servizio operativo. Account creati non equivalgono a deploy.

## Fonti ufficiali

- https://supabase.com/pricing
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://supabase.com/docs/guides/auth/auth-smtp
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan
- https://firebase.google.com/pricing
- https://developer.apple.com/documentation/cryptokit
- https://developer.apple.com/documentation/cryptokit/aes/gcm
