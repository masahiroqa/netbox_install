# redhat version 8.6
# 構成管理 PoC のversionに合わせてある
FROM redhat/ubi8:8.6 

# 現状すでにインストールされているpythonはインストールする
RUN yum install -y python39

## ここから netboxのインストール作業

### postgreSQL install
# repositoryにposgreが無い場合は下記コマンドでrepositoryに追加する
RUN dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-aarch64/pgdg-redhat-repo-latest.noarch.rpm
# posgre install versionは10になるはず
RUN dnf install -y postgresql-server
# expect コマンドをinstall
RUN dnf -y install https://rpmfind.net/linux/centos/8-stream/BaseOS/aarch64/os/Packages/expect-5.45.4-5.el8.aarch64.rpm

# postgresql 初期化
USER postgres
COPY ./postgresql_setting.exp /
RUN expect /postgresql_setting.exp
USER root

# 初期設定用スクリプトをコピー
COPY ./init_setting.sh /
RUN chmod 777 /init_setting.sh
COPY init_setting.exp /
RUN chmod 777 /init_setting.exp

# container 起動後に実行
# RUN systemctl start postgresql-12

### redis install
#RUN dnf install -y redis
# 事前に必要なパッケージを入れる
RUN yum install -y make gcc wget tcl procps-ng

# redisをソースから引っ張ってくる
RUN wget https://download.redis.io/redis-stable.tar.gz
RUN tar xzvf redis-stable.tar.gz
WORKDIR "/redis-stable"
RUN make install
RUN redis-server &
WORKDIR "/"

# netbox install
# 事前に必要なパッケージを入れる
RUN dnf install -y git

# install 開始
RUN mkdir -p /opt/netbox/
WORKDIR "/opt/netbox"
RUN git clone -b master --depth 1 https://github.com/netbox-community/netbox.git .
RUN groupadd --system netbox
RUN adduser --system -g netbox netbox
RUN chown --recursive netbox /opt/netbox/netbox/media/
WORKDIR "/opt/netbox/netbox/netbox/"
COPY configuration.py ./configuration.py

# 必要なpython moduleをinstall
WORKDIR "/opt/netbox"
RUN pip3 install -r requirements.txt 
RUN python3 -m pip install Django

# shell script用にdirectoryを変える
WORKDIR "/opt/netbox/netbox/netbox/"