# DNSSEC - StatusFile

Pulls the latest DNSSEC/DNS health-check report files from a remote host down to the NAS, displays today's report, then deletes the local copy of that report.

---

## Usage

```console
chmod +x "DNSSEC - StatusFile.sh"
bash "DNSSEC - StatusFile.sh"
```

Run it from any working directory — all source and destination paths are absolute.

Prerequisites:

- SSH access (key-based, since the script is non-interactive) to `admina@10.0.0.214`.
- The destination folders `/volume1/Dragic/Rap/DNS_Status` and `/volume1/Dragic/Rap/DNS_Status/Old` must already exist on the NAS — the script does not create them.
- A report file named `Sundhedscheck-<YYYY-MM-DD>.txt` (today's date) must already exist under `/volume1/Dragic/Rap/DNS_Status` after the copy step, or the final `more` command will fail with "No such file or directory".

---

## What the Script Does

### Step 1 – Copy current reports
Runs `scp -r admina@10.0.0.214:/home/admina/DNSSEC/*.txt /volume1/Dragic/Rap/DNS_Status`, copying all current `.txt` report files from the remote host into the NAS destination folder.

### Step 2 – Copy archived reports
Runs `scp -r admina@10.0.0.214:/home/admina/DNSSEC/Old/*.txt /volume1/Dragic/Rap/DNS_Status/Old`, copying the remote host's `Old/` subfolder of archived reports into the corresponding local `Old` folder.

### Step 3 – Display today's report
Runs `more "/volume1/Dragic/Rap/DNS_Status/Sundhedscheck-$(date +\%F).txt"`, opening today's dated report file in a pager for viewing.

### Step 4 – Delete today's report
Runs `rm "/volume1/Dragic/Rap/DNS_Status/Sundhedscheck-$(date +\%F).txt"`, deleting the local copy of today's dated report after it has been displayed.

---

## Notes

- Not idempotent in a meaningful sense, but safe to re-run: each run just re-copies whatever `.txt` files currently exist remotely, overwriting the local copies (except today's report, which is deleted at the end of each run — see below).
- Deletes today's local report after displaying it: only the dated `Sundhedscheck-<YYYY-MM-DD>.txt` file is removed; the other copied `.txt` files and the `Old/` archive are left in place. Since the report is re-copied fresh from the remote host on the next run, this doesn't lose data as long as the remote copy still exists — but it does mean the NAS never accumulates a local history of daily reports outside of `Old/`.
- `more` is a pager and blocks waiting for user input — this script is meant to be run interactively (e.g. at a terminal), not unattended via cron/Task Scheduler, unlike the "Copy ..." scripts elsewhere in this folder that end with a plain `ls`.
- No error handling: if either `scp` fails (host unreachable, no matching files, auth failure) the script continues on to the next step anyway; if today's report file doesn't exist yet, `more` will error out and the subsequent `rm` will also fail (harmlessly, since there's nothing to delete).
- The remote host `10.0.0.214` is presumably where `Dns_Sundhedstjek.sh` (in the `Web_source` repo) runs and writes its `Sundhedscheck-*.txt` output under `/home/admina/DNSSEC/` — this script is the retrieval/viewing half of that workflow, not documented as a pair anywhere else.
- Hardcoded values: remote host/IP (`10.0.0.214`), remote user (`admina`), and all NAS destination paths (`/volume1/Dragic/Rap/DNS_Status`, `.../Old`).
- The `\%F` in the `date` call is crontab-style escaping of `%` (needed there because `%` is special to cron); it's unnecessary in a plain shell script but harmless — the backslash is simply consumed by the shell and `date` still receives `%F`.
