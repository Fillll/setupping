# Instructions for Claude to do stuff

## 0. Prerequisites

```bash
# Make sure the system is current
$ sudo apt update && sudo apt full-upgrade -y

# Install a few helpers we’ll need later
$ sudo apt install -y curl git build-essential
```

## 1-a. Install and enable vnStat

```bash
# 1. Install the package (vnstati adds PNG graph output)
$ sudo apt install -y vnstat vnstati

# 2. Start the service now and at every boot
$ sudo systemctl enable --now vnstat

# 3. Tell vnStat which interface(s) to track
$ sudo vnstat -u -i eth0      # or wlan0, enp1s0, etc.

# 4. Verify it’s logging
$ vnstat --oneline
```

## 1-b. Lock SSH to key-only log-ins

Locally.

```bash
ssh-copy-id fil@rpi-server-02.local
# Or specific key
# ssh-copy-id -i .ssh/id_ed25519.pub fil@rpi-server-02.local
```

Edit (or create) `/etc/ssh/sshd_config.d/00-local.conf` on the Pi:

```conf
# Allow only key auth for everyone
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no

# Optional extras
PermitRootLogin prohibit-password   # root only via key/sudo
AllowUsers fil                      # whitelist local user
```

Reload SSH without kicking yourself out:
```bash
# in the still-open session
# Test first!
$ sudo systemctl reload sshd
```

## 2. Install Claude Code

```bash
# 1. Grab NVM
$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
$ exec $SHELL          # reload your shell so `nvm` is in PATH

# 2. Install the latest LTS release of Node + npm
$ nvm install --lts

# 3. Verify
$ node -v   # e.g. v20.x.x
$ npm -v    # e.g. 10.x.x
```

```bash
$ npm install -g @anthropic-ai/claude-code
```

```bash
$ claude login          # opens a browser tab → sign in with your Anthropic account
```
