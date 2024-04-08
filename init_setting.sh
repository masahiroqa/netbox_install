#!/bin/bash

# postgresql 初期設定コマンド
systemctl start postgresql-12
PGPASSWORD=root psql -U postgres -c "CREATE DATABASE netbox;"
PGPASSWORD=root psql -U postgres -c "CREATE USER netbox WITH PASSWORD 'root';"
PGPASSWORD=root psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;"

# redis を起動する
redis-server &
echo -e "\n\n"

# netbox 初期設定コマンド
NETBOX=$(python3 /opt/netbox/netbox/generate_secret_key.py)
echo $NETBOX
sed -i "s/SECRET_KEY = ''/SECRET_KEY = '$NETBOX'/" /opt/netbox/netbox/netbox/configuration.py
/opt/netbox/upgrade.sh
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
expect /init_setting.exp
deactivate

ln -s /opt/netbox/contrib/netbox-housekeeping.sh 
cd /opt/netbox/netbox

python3 manage.py runserver 0.0.0.0:8000 --insecure &