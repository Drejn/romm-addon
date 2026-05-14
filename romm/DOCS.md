# RomM - ROM Manager

RomM è un gestore di ROM self-hosted con player web integrato (EmulatorJS).
Permette di organizzare, sfogliare e giocare alle tue ROM direttamente dal browser.

## Configurazione

### Database

Puoi scegliere tra due modalità:

**SQLite (consigliato per iniziare)**
- Imposta `db_type: sqlite`
- Nessuna configurazione aggiuntiva richiesta

**MariaDB (consigliato per librerie grandi)**
- Installa l'addon **MariaDB** ufficiale di Home Assistant
- Crea un database chiamato `romm` dall'addon MariaDB
- Imposta `db_type: mariadb` e compila i campi:
  - `mariadb_host`: di solito `core-mariadb`
  - `mariadb_user` e `mariadb_password`: le credenziali che hai impostato in MariaDB
  - `mariadb_database`: `romm`

### Libreria ROM

Imposta `rom_library_path` con il percorso dove hai le tue ROM.
Il percorso deve essere dentro `/share/`, ad esempio `/share/roms`.

La struttura delle cartelle deve essere:
```
/share/roms/
├── gba/
│   └── roms/
│       └── gioco.gba
├── snes/
│   └── roms/
│       └── gioco.sfc
└── n64/
    └── roms/
        └── gioco.z64
```

### Metadati (opzionale ma consigliato)

Per ottenere copertine e informazioni sui giochi registrati su [IGDB](https://api-docs.igdb.com/#account-creation):
- Crea un account Twitch Developer
- Genera `Client ID` e `Client Secret`
- Inseriscili nei campi `igdb_client_id` e `igdb_client_secret`

## Accesso

Dopo l'avvio, RomM è accessibile su:
```
http://IP-DEL-TUO-HA:8998
```

Al primo accesso ti verrà chiesto di creare l'utente amministratore.

## Note

- I dati di RomM (database SQLite, risorse, copertine) sono salvati in `/data/romm` e persistono tra i riavvii.
- La `ROMM_AUTH_SECRET_KEY` viene generata automaticamente al primo avvio e salvata in `/data/romm_secret_key`.
