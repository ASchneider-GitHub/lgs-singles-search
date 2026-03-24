# lgs-singles-search
### Using questionable API calls to retrieve local store inventory for Magic: the Gathering singles.

#### 1. Clone & Prep
```
git clone https://github.com/ASchneider-GitHub/lgs-singles-search.git
cd lgs-singles-search
chmod +x *.sh
```

#### 2. Copy the template and fill in your Cloudflare keys:
```
cp .cloudflare.env.example .cloudflare.env
vim .cloudflare.env
```

#### 3. Build & Launch
```
./setup.sh
```

#### 4. Add this to `crontab -e` to sync bad actors every 10 minutes:
```
*/10 * * * * /bin/bash $HOME/lgs-singles-search/update-ban-list.sh >> $HOME/lgs-singles-search/cron.log 2>&1
```
