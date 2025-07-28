```
rsync -av root@larkbox:/home/jvisser/photoprism-docker-compose ./data
sudo systemctl start docker-photoprism-photoprism.service
sudo systemctl stop docker-photoprism-photoprism.service
sudo systemctl status docker-photoprism-photoprism.service
sudo docker exec photoprism-photoprism photoprism restore -i -f
sudo docker system prune
```