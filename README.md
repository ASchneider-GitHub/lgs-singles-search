# lgs-singles-search
Using questionable API calls to retrieve local store inventory for Magic: the Gathering singles.

Once the repository is pulled, you must update `.cloudflare.env.example` with your Cloudflare API information, and then rename the file to `.cloudflare.env`.

Run `./setup.sh` to build the image and launch the container

Use `crontab -e` to create a scheduled event to ban unwanted IPs
```
*/10 * * * * /bin/bash /home/$USERNAME/lgs-singles-search/update-ban-list.sh >> /home/$USERNAME/lgs-singles-search/cron.log 2>&1
```
