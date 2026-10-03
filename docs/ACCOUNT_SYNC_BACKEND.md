# Backend account sync — fondazione

Status: migrations 001–003 deployed to the Thravik Supabase project. Sync,
vault recovery and device membership SQL tests pass on the remote database
inside rolled-back transactions; schema lint reports no errors. Anonymous
PostgREST calls cannot access device/vault RPCs. Client end-to-end testing and
the production security gates remain required.

## Email configuration

The six versioned templates in `backend/supabase/templates` use English copy
and Thravik branding. Confirmation, sign-in and reauthentication show OTPs;
password recovery and email change also show OTPs; invitations retain their
confirmation link. Recovery returns to the native app to set a new password.
The dark/orange template revision must be published through the Management API
and verified by reading it back; earlier hosted templates were already published.
Run `python3 backend/tests/template-contract.py` for the local template contract.
Brevo SMTP is configured with `hello@thravik.com` and sender name `Thravik`.
Never commit SMTP credentials or a Management API token. Apply only template
fields when updating hosted email; pushing the entire local auth configuration
would also replace unrelated remote settings.

Google consent branding belongs to the matching Google Cloud OAuth client.
Renaming the Supabase project or changing email HTML does not verify that brand.

## Avvio locale

Dalla radice repository:

```sh
supabase start --workdir backend
supabase db reset --workdir backend
backend/tests/run.sh
supabase stop --workdir backend
```

In alternativa, `sh backend/tests/run-postgres.sh` usa immagine Postgres 17 già
presente e uno stub auth.uid per testare SQL/RLS, senza porte o volumi host.
Non sostituisce il collaudo auth/PostgREST nel progetto Supabase.

Supabase CLI e Docker sono strumenti di sviluppo, nessuna nuova dipendenza app.
Email locali intercettate da Inbucket; Google/SMTP reali richiedono configurazione
provider. Le chiavi prodotte dall'ambiente locale non vanno versionate.

## Login riuscito, device/vault indisponibili

Google ed email usano GoTrue, mentre device e vault richiedono le migration
Postgres del progetto. Abilitare i provider auth non crea le RPC della sync.
`PGRST202` su `sync_device_list` o `vault_recovery_get` indica RPC non presente
nella schema cache: verificare migration applicate e reload PostgREST. Il client
segnala backend non configurato e non abilita cloud senza device locale approvato.

Per un progetto remoto, autenticare Supabase CLI, collegare il progetto corretto
con `supabase link --project-ref PROJECT_REF --workdir backend`, quindi controllare
`supabase db push --dry-run --workdir backend` prima di applicare le migration
con `supabase db push --workdir backend`. Non eseguire `db reset` sul remoto.
Migration richieste: foundation (001), vault recovery (002), device membership
(003). La chiave publishable nel bundle non autorizza migration amministrative.

Email richiede template OTP con `{{ .Token }}` e consegna SMTP verificata;
il solo link magico non completa la schermata di inserimento codice del client.

## Contratto RPC

`POST /rest/v1/rpc/sync_push`, bearer access token Supabase:

```json
{
  "request": {
    "mutation_id": "UUID",
    "record_id": "UUID",
    "expected_revision": 0,
    "deleted": false,
    "collection": "spaces",
    "encrypted_payload": "base64 dell’envelope cifrato JSON"
  }
}
```

L’envelope include epoch, nonce, ciphertext e tag. I dati applicativi restano nel payload cifrato; collection tecnica, ID opachi
e metadati revision/cursor sono visibili.
Il client deve autenticare account ID, record ID, epoch e protocollo via AAD.
Il server verifica formato e dimensione, non può provare che il payload sia cifrato.
Non inviare dati chiari nelle chiavi ammesse del JSON.

Risposta accettata: richiesta originale più `status: accepted`, `revision: 1`,
`cursor: 1`. Il pull restituisce gli stessi campi mutation e revision/cursor,
oltre a owner_id; lo stato accepted è implicito nel feed.
Conflitto CAS: `{ "status": "conflict", "revision": 2 }`; nessuna scrittura.
Conflitti non sono registrati come successi idempotenti. Retry di un successo
restituisce lo stesso risultato; stesso mutation ID con richiesta diversa fallisce.

`sync_pull(after_cursor: 0, page_size: 100)` restituisce cambiamenti ordinati,
al massimo 100. Avanzare al cursor dell'ultima riga solo dopo applicazione locale
persistente. Pagina vuota non cambia cursor. Tombstone è un record cifrato marcato
`deleted`; non è eliminato dal feed. Nessuna compattazione in questa fondazione.

La riga account viene bloccata fino al commit di ogni push: i cursori dello stesso
account non possono diventare visibili fuori ordine. Account diversi indipendenti.
Record, feed e deduplicazione sono atomici; rollback non consuma cursori.

## Confini e sicurezza

RLS filtra record/feed per auth.uid; nessuna scrittura diretta client. RPC push
security definer usa search_path vuoto, riferimenti qualificati e owner derivato
esclusivamente dalla sessione. Account e dedup sono in schema privato senza grant.
Nessun accesso anonimo. La cancellazione auth.users propaga su tutte le tabelle.

Limite richiesta 256 KiB, feed massimo 10.000 mutazioni per account. Questo cap
arresta ulteriori scritture con errore client tipizzato quotaExceeded: serve migrazione di retention/checkpoint prima di
superarlo, non cancellazione manuale del feed. Storage totale e frequenza non sono
quote operative complete; anche le SELECT dirette richiedono limiti API/traffico.

**Non pubblicare la sync password con questa sola fondazione.** Login account
non dimostra membership del dispositivo. Mancano verifica firme/membership,
rotazione/revoca, checkpoint, quote/rate limiting, backup/restore,
load test e prova end-to-end su due installazioni. Nessuna registrazione
di dispositivo non firmata viene presentata come controllo crittografico.

I test SQL coprono due utenti, RLS, grant, CAS, retry, mismatch, tombstone,
sequenza e paginazione; eseguono rollback completo. Il runner Postgres aggiunge due transazioni concorrenti: il secondo cursor
attende il commit del primo. Load test e ambiente Supabase restano gate separati.

## Recovery password

Migration 002 espone `vault_recovery_get` e `vault_recovery_create`: root key
cifrata con codice casuale da 256 bit, mai codice o root in chiaro. Una envelope
per account, immutabile; retry identico accettato, sostituzione negata. RLS e RPC
verificati da `vault_recovery.sql` in entrambi i runner.

## Firma iCloud

Build con certificato Apple e profilo macOS per bundle esplicito:

```sh
ICLOUD_PROVISIONING_PROFILE=/path/profile.provisionprofile \
REQUIRE_ICLOUD_PASSWORDS=1 make dev
```

Script valida scadenza/team/bundle/access group, applica entitlements autorizzati,
incorpora profilo, verifica certificato autorizzato dal profilo e firma. Nessun fallback ad hoc in questa modalità.
`REDENT_ICLOUD_ACCESS_GROUP` opzionale deve essere autorizzato dal profilo;
in assenza usa TEAM.bundleID. Per passkey e iCloud usare lo stesso profilo
con entrambe le autorizzazioni. Provisioning Apple reale ancora da collaudare.
