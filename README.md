# nginx-rp
nginx-rp は Docker を用いて Reverse Proxy Server を容易に構築できるアプリケーションです．

### 設定
#### サーバの追加 / 削除
##### 追加
* conf ディレクトリ以下に *.conf ファイルを追加し，設定を記述してください．
* *.conf 以外のファイルは無視されます．ファイル名に注意してください．
* conf ディレクトリにはサンプルファイルがあります．コピーして利用することもできます．
```bash
cp conf/example_com.conf.sample conf/my_server.conf
```
* 設定の記述方式については下記の設定を確認してください．
##### 削除 / 無効化
* conf ディレクトリから対応するサーバの conf ファイルを削除してください．
* また，ファイル名を *.conf.disabled など *.conf 以外に変更しても設定が無効化できます．
#### 設定ファイルの記述
##### HTTP サーバ
* 以下のような記述になります
```
 1  server{
 2          listen 80;
 3          server_name my.server.com;
 4          access_log /var/log/nginx/my_server_access.log;
 5          error_log /var/log/nginx/my_server_error.log;
 6          location / {
 7                  proxy_pass http://other.server.com:80;
 8                  proxy_set_header        Host $host;
 9                  proxy_set_header        X-Real-IP $remote_addr;
10                  proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
11                  proxy_set_header        X-Forwarded-Proto $scheme;
12          }
13  }
```
* 2行目はサーバのポートです．特別な理由がなければ80番になるはずです．
* 3行目はサーバの名前です．この名前で nginx-rp にアクセスされると proxy_pass で指定したサーバにプロキシされます．
* 4，5行目はログファイルのパスです．コンテナ内の /var/log/nginx は log/ にバインディングされているため，この設定では log/ に my_server_access.log と my_server_error.log が保存されます．/varlog/nginx 以外のパスが指定された場合，ログはホストに保存されません．
* 6~12行目は サーバのパスごとの挙動になります．この場合では / 以下 (つまりすべてのアクセス) が7行目で指定した http://other.server.com:80 にプロキシされます．
* locaion は複数指定することや部分一致などより高度な書き方ができます．詳しくは nginx の設定マニュアルを確認してください．

##### HTTPS サーバ
```
 1 server{
 2         listen *:443 ssl;
 3         server_name my.server.com;
 4         access_log /var/log/nginx/my_server_access.log;
 5         error_log /var/log/nginx/my_server_error.log;
 6         ssl_certificate /etc/nginx/ssl/live/my.server.com/cert.pem;
 7         ssl_certificate_key /etc/nginx/ssl/live/my.server.com/privkey.pem;
 8         ssl_protocols TLSv1.2 TLSv1.3;
 9         location / {
10                 proxy_pass http://other.server.com;
11                 proxy_set_header        Host $host;
12                 proxy_set_header        X-Real-IP $remote_addr;
13                 proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
14                 proxy_set_header        X-Forwarded-Proto $scheme;
15         }
16 }
```
* 基本的な記述方法は HTTP サーバと同様です．
* 2行目で ssl により SSL/TLS 対応であることを示します．
* 6，7行目で SSL 証明書のパスを指定します．コンテナ内の /etc/nginx/ssl と ホストの ssl はバインディングされています．また，下記の認証スクリプトを使用する場合，SSL 証明書は ssl/live/[server_name]/ に配置されます．なので，認証スクリプトを使用する場合， 上記コードのように指定することを推奨します．
* 8行目では TLS のバージョンを指定します．これを指定しない場合，ブラウザサポート外バージョンの TLS が使用され，サーバのアクセスに失敗する可能性があります．

##### デフォルトサーバ
* 設定ファイルに記述された server_name 以外の名前でアクセスされた場合，アルファベット順最初の設定ファイルに記述されたサーバにアクセスされた扱いになります．
* ここで，default_server を追加することで，上記の挙動を無効にしてデフォルトの挙動を設定できます．設定は以下のような記述になります．
```
 1  server {
 2      listen 80 default_server;
 4      return 404;
 5  }
 6
 7  server {
 8      listen *:443 ssl default_server;
10      ssl_certificate /etc/nginx/ssl/live/bw.nomlab.org/cert.pem;
11      ssl_certificate_key /etc/nginx/ssl/live/bw.nomlab.org/privkey.pem;
13      return 404;
14  }
15
```
* 2，8行目で default_server であることを示します．
* 4，13行目で 404 (NotFound) を返します．


### SSL/TLS 認証
* nginx-rp は [Let's encrypt](https://letsencrypt.org/ja/) (および認証ランタイムの certbot) を利用して，半自動的に SSL/TLS 認証を行えます．
#### 準備
* 認証スクリプトでは Let's encrypt の ACME チャレンジを使用します．
* この手法は認証するサーバの /.well-known/acme-challenge/ 以下に指定した文字列が記述されたファイルが配置されていることを確認できれば認証されるという仕組みになっています．
* これを自動的に行えるようにするため，サーバの設定ファイルに以下を以下のように記述します．
```
  1  server{
  2          listen 80;
  3          server_name my.server.com;
  4          access_log /var/log/nginx/my_server_access.log;
  5          error_log /var/log/nginx/my_server_error.log;
+ 6          location /.well-known/acme-challenge/ {
+ 7                  root /webroot/
+ 8          }
  9          location / {
 10                  proxy_pass http://other.server.com:80;
 11                  proxy_set_header        Host $host;
 12                  proxy_set_header        X-Real-IP $remote_addr;
 13                  proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
 14                  proxy_set_header        X-Forwarded-Proto $scheme;
 15          }
 16  }
```
* 6~8行目の記述により，認証を自動化できます．

#### 認証
* 以下のコマンドにより認証を行います．
```bash
./cert.sh -d "myserver1.com, myserver2.com" -m "my.mail.addr@mail.com"
```
* 認証するサーバを -d オプション以降にカンマ区切りで記述します．
* 認証者のメールアドレスを -m オプションで指定します．なお，指定したメールアドレスには認証切れの通知などが送信されます．
* -d オプションでドメインを指定する代わりに --domains-from-config を利用手できます．このオプションを用いると conf 以下の全設定ファイル中の server_name を読み取り，認証ドメイン名として利用します．
* 認証だけでは自動的にサーバが更新されるわけではないので，下記の使用例に合わせてサーバを再起動してください．

#### 認証の自動化
* Let's encrypt は3ヶ月と比較的短期間で認証が切れます．
* そのため，認証を自動化することを推奨します．
* 認証の自動化には以下のようなコマンドを実行します．
```bash
crontab -u root -e
```
* 上記のコマンドにより crontab 編集画面が開くため，最終行に以下のように追記してください．
```crontab
0 4 1 * * /path/to/install/nginx-rp/cert.sh --domains-from-config -m "my.mail.addr@mail.com" && systemctl restart nginx-rp.service
```
* "0 4 1 * *" は 毎月1日の4時0分にコマンドを実行するという意味です．指定の仕方については crontab のマニュアルを確認してください．
* "/path/to/install/nginx-rp" は nginx-rp を配置しているディレクトリに合わせて変更してください．
* "my.mail.addr@mail.com" は通知を行うメールアドレスです．使用環境に合わせて指定してください．
* "systemcl restart nginx-rp.service" はサーバの再起動コマンドです．起動スクリプトかsystemctlかなど状況に合わせて変更してください．


## 使用
#### 準備
* Docker のインストール
  * 本アプリケーションは Docker を前提として動作します．
  * [こちら](https://docs.docker.com/engine/install/) を参考に Docker をインストールしてください．

#### 起動
* 起動には起動用スクリプト launch.sh を使用して，以下のように実行します．
```bash
./launch.sh start
```
* また，バックグラウンドで起動することもできます．この場合，nginx のログを確認することはできません．
```bash
./launch.sh start -d
```
* ホスト側のバインドポートを変更することができますが，変更は非推奨です．
```bash
./launch.sh start -p 8080
```
#### 停止/再起動
* 起動用スクリプトで停止できます．
```shell
$ launch.sh stop
```
* また，再起動も可能です．
```shell
$ launch.sh restart
```

#### systemd との連携
* nginx-rp を systemd のサービスとして登録することができます．
* サービスに登録することで，PC起動時の自動起動や，異常終了時の再起動などができます．

##### 準備
* まず，サンプルとサービスファイルを配置してください．
``` bash
cp systemd_conf/nginx-rp.service /etc/systemd/system/
```
* 次に，コピーしたサービスファイルで必要な項目を書き換えてください．
```bash
vim /etc/systemd/system/nginx-rp.service
```
##### 管理方法
* systemd で nginx-rp を起動している場合，以下のコマンドで管理できます．
    * 起動
    ```bash
    systemctl start nginx-rp
    ```
    + 停止
    ```bash
    systemctl stop nginx-rp
    ```
    + 再起動
    ```bash
    systemctl restart nginx-rp
    ```
    + ステータス確認
    ```bash
    systemctl status nginx-rp
    ```
    + 自動起動
    ```bash
    systemctl enable nginx-rp
    ```
    + 自動起動の無効化
    ```bash
    systemctl disable nginx-rp
    ```
