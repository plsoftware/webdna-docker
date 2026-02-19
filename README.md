# WebDNA Docker Image

Apache `mod_webdna` 8.6.5 on Ubuntu 24.04 LTS (Noble Numbat).

## Files

```
webdna-docker/
├── Dockerfile          ← builds the image
├── entrypoint.sh       ← starts WebDNAMonitor and Apache on container start
├── docker-compose.yml  ← used by Portainer to deploy the container
└── README.md
```

---

## Requirements

- A machine running Docker (your Portainer host is fine)
- SSH access to that machine
- Portainer installed and running

---

## Step 1 — SSH into your Docker host

```bash
ssh your-user@your-docker-host
sudo su
```

---

## Step 2 — Create a build folder and copy the files

```bash
mkdir -p ~/webdna-docker
cd ~/webdna-docker
```

Copy `Dockerfile` and `entrypoint.sh` into this folder, then make the entrypoint executable:

```bash
chmod +x entrypoint.sh
```

---

## Step 3 — Build the image

```bash
docker build -t webdna:8.6.5 .
```

This will take a few minutes. When complete you will see:

```
Successfully tagged webdna:8.6.5
```

Verify the image exists:

```bash
docker images | grep webdna
```

---

## Step 4 — Create the site directory

```bash
mkdir -p /opt/webdna/www
```

This is where your `.dna` site files will live on the host.

---

## Step 5 — Deploy in Portainer

1. Open Portainer in your browser
2. Go to **Stacks → Add stack**
3. Name the stack `webdna-server-8-6-5`
4. Select **Web editor** and paste the contents of `docker-compose.yml`
5. Click **Deploy the stack**

---

## Step 6 — Test the installation

Open your browser and go to:

```
http://your-docker-host:8081/WebCatalog
```

Login with `admin` / `admin`.

---

## Accessing WebDNA

| URL | Purpose |
|---|---|
| `http://your-host:8081/WebCatalog` | WebDNA admin interface |
| `http://your-host:8081/WebCatalog/christophes_tearoom/` | Built-in demo store |
| `http://your-host:8081/sites/` | Your own site files |

---

## Your Site Files

Place your `.dna` files in `/opt/webdna/www` on the host. They will be served from:

```
http://your-host:8081/sites/
```

The `/var/www/html/WebCatalog` directory inside the container is left untouched — this is where the WebDNA admin interface and demo files live. Do not mount a volume directly to `/var/www/html` as this will hide the WebCatalog directory.

---

## Volumes

| Volume | Purpose |
|---|---|
| `/opt/webdna/www` | Your site files (bind mount — edit live on the host) |
| `webdna-server-8-6-5-data` | WebDNA globals & databases (persisted across rebuilds) |
| `webdna-server-8-6-5-logs` | Apache logs (persisted across rebuilds) |

---

## Useful Commands

Check container logs:
```bash
docker logs webdna-server-8-6-5
```

Confirm WebDNAMonitor is running:
```bash
docker exec webdna-server-8-6-5 ps aux | grep WebDNA
```

Drop into a shell inside the container:
```bash
docker exec -it webdna-server-8-6-5 bash
```

---

## Rebuilding After Changes

If you modify `Dockerfile` or `entrypoint.sh`:

```bash
cd ~/webdna-docker
chmod +x entrypoint.sh
docker build --no-cache -t webdna:8.6.5 .
```

Then in Portainer go to your stack and click **Redeploy**.

---

## Sharing the Image

### Option 1 — Share the files (recommended)

Anyone with these four files can build the image themselves:

```bash
chmod +x entrypoint.sh
docker build -t webdna:8.6.5 .
```

### Option 2 — Push to Docker Hub

```bash
docker login
docker tag webdna:8.6.5 yourdockerhubuser/webdna:8.6.5
docker push yourdockerhubuser/webdna:8.6.5
```

Then update the `image:` line in `docker-compose.yml` to `yourdockerhubuser/webdna:8.6.5`.

### Option 3 — Export as a file

```bash
# On the source machine
docker save webdna:8.6.5 | gzip > webdna-8.6.5.tar.gz

# On the receiving machine
docker load < webdna-8.6.5.tar.gz
```

---

## Known Issues & Solutions

### `systemctl: not found` (exit code 127) during build
Docker has no systemd. The WebDNA postinstall script calls `systemctl` to start
services after install. A fake `systemctl` is created in `/usr/bin` before the
install and removed immediately after, allowing the installer to complete successfully.

### `mod_webdna.so` not loading
The postinstall script sets `mod_webdna.so` to `644` (no execute bit). Apache
cannot load a module without execute permission. The Dockerfile explicitly sets
it to `755` after install.

### `/WebCatalog` returns 404
The WebDNA installer places the admin and demo files in `/var/www/html/WebCatalog`.
Mounting a volume directly to `/var/www/html` hides this directory. Always mount
your site files to a subdirectory such as `/var/www/html/sites`.

### "Sorry WebDNA server not running"
WebDNAMonitor must be started from within the `/usr/lib/cgi-bin/WebCatalogEngine`
directory. The entrypoint script handles this automatically:
```bash
cd /usr/lib/cgi-bin/WebCatalogEngine && ./WebDNAMonitor &
```

### Port already in use
If port 8081 is taken, change the port mapping in `docker-compose.yml`:
```yaml
ports:
  - "8082:80"
```
