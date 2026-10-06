# Laptop Setup - Setup.sh

Interaktivt setup-script til Debian/Ubuntu-baserede laptops. Viser status for en liste af mine mest brugte CLI-værktøjer (installeret eller ej, og om den installerede version er den seneste tilgængelige), og lader dig vælge flere værktøjer på én gang, som så installeres/opdateres samlet via `apt-get`.

---

## Usage

```console
chmod +x Setup.sh
sudo bash Setup.sh
```

Prerequisites:

- Et Debian/Ubuntu-baseret system med `apt-get`/`dpkg`/`apt-cache` og internetadgang.
- Root-adgang (scriptet tjekker selv for dette og afbryder med en fejl hvis det ikke køres som root/sudo).

---

## What the Script Does

### Step 1 – Opdater pakkeliste
Kører `apt-get update -qq` for at hente den nyeste pakkeindeks fra de konfigurerede repositories.

### Step 2 – Vis status for hvert værktøj
For hvert værktøj i `TOOLS`-listen (nederst i scriptet, som `pakkenavn:beskrivelse`) tjekkes:

- Installeret version via `dpkg-query -W -f='${Version}' <pakke>`.
- Nyeste tilgængelige version via `apt-cache policy <pakke>` (`Candidate:`-linjen).

Resultatet vises i en nummereret tabel med et status-ikon:

| Ikon | Betydning |
| --- | --- |
| ✘ (rød) | Ikke installeret |
| ✔ (grøn) | Installeret, og det er den seneste version |
| ⚠ (gul) | Installeret, men en nyere version er tilgængelig (viser `installeret → seneste`) |

### Step 3 – Vælg og installer værktøjer
Du bliver bedt om at angive numre (fra tabellen i Step 2) adskilt af mellemrum eller komma, fx `1 3 5`, eller skrive `alle` for at vælge samtlige værktøjer. Alle valgte pakker installeres/opdateres i ét samlet `apt-get install -y`-kald, så de installeres på samme tid. Tomt input (Enter) afslutter scriptet uden at ændre noget.

---

## Værktøjer der indgår

Listen dækker kun værktøjer der køres fra selve pc'en/laptoppen (ikke router- eller NAS-scripts):

**Kerne/CLI:** `htop`, `tree`, `curl`, `wget`, `git`, `unzip`, `krusader`, `veracrypt`

**Backup & filer:** `rsync`, `7zip`, `libimage-exiftool-perl` (exiftool), `darktable`, `libheif-examples`, `wkhtmltopdf`

**System & opdatering:** `fwupd`, `snapd`, `flatpak`, `plocate`, `dkms`

**Udvikling:** `python3-pip`, `npm`

**Netværk & fjernadgang:** `openssh-client`, `wireguard-tools`, `dnsutils`, `fzf`

**Terminal & diverse:** `screen`, `pv`, `dmidecode`, `eject`

Den fulde liste med beskrivelser står i `TOOLS`-arrayet i scriptet.

---

## Tilføj/fjern værktøjer

Redigér `TOOLS`-arrayet i toppen af scriptet. Hver linje har formatet:

```bash
"apt-pakkenavn:kort beskrivelse"
```

Pakkenavnet skal matche et gyldigt `apt`-pakkenavn på systemet.

---

## Notes

- Antager et `apt`-baseret system (Debian/Ubuntu) — virker ikke som det er på andre distributioner (fx Arch, Fedora, OpenWrt).
- Ikke-eksisterende pakkenavne i `TOOLS` vil blive vist som "ikke installeret" i status-oversigten, men vil fejle når `apt-get install` forsøger at installere dem.
- `veracrypt` er ikke i standard Debian/Ubuntu-repositories. Den skal typisk tilføjes via en PPA (fx `ppa:unit193/encryption` på Ubuntu) eller ved at installere `.deb`-pakken direkte fra [veracrypt.fr](https://www.veracrypt.fr/) — indtil kilden er tilføjet, vil scriptet vise den som "ikke installeret", og `apt-get install veracrypt` vil fejle.
- `7zip` (moderne 7-Zip CLI, kommandoen hedder `7zz`) findes kun på nyere Debian/Ubuntu-udgivelser. På ældre systemer, hvor pakken ikke findes, skal `p7zip-full` (kommandoen `7z`) bruges i stedet — ret pakkenavnet i `TOOLS` hvis det er tilfældet på din maskine.
- `dkms` er kun generelt nyttig, hvis du fra tid til anden skal bygge tredjeparts-kernel-moduler (fx Wi-Fi-drivere som i `Install_AWUS036ACH.sh`) — den installerer ikke selve driveren.
- Scriptet ændrer ikke systemet, før du selv aktivt vælger værktøjer i Step 3 — status-visningen alene er ikke-destruktiv (udover `apt-get update`, som kun opdaterer pakkeindekset).
