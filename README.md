# nginx-RPの設定ファイル

## 使い方

#### スクリプトを用いる方法
1. 起動
```shell
$ launch.sh start
```
2. 起動 (バックグラウンドで動作させる場合)
```shell
$ launch.sh start -d
```
3. 停止
```shell
$ launch.sh stop
```
5. 再起動
```shell
$ launch.sh restart -d
```
6. ステータス確認
```shell
$ launch.sh status
```

より詳細な使い方については以下のコマンドを実行
```shell
$ launch.sh help
```

#### systemd を用いる手法
+ 事前準備
    1. `systemd_conf/nginx-rp.service` を `/etc/systemd/system` にコピー
    ```shell
    # cp systemd_conf/nginx-rp.service /etc/systemd/system/
    ```
    2. コピーした `nginx-rp.service` を書き換える
    ```shell
    # vim /etc/systemd/system/nginx-rp.service
    ```
+ 管理
    + 起動
    ```shell
    # systemctl start nginx-rp
    ```
    + 停止
    ```shell
    # systemctl stop nginx-rp
    ```
    + ステータス確認
    ```shell
    # systemctl status nginx-rp
    ```
    + 自動起動
    ```shell
    # systemctl enable nginx-rp
    ```


### リバースプロキシ設定の変更

* サーバの追加  
conf 以下に対応するサーバの設定ファイル ( *.conf) ファイルを追加する．
conf/example_com.conf.sample を参考にすると良い．

* サーバの削除  
conf/ 以下の設定ファイル (*.conf) を削除することでリバースプロキシが無効になる．
または，拡張子を .conf 以外に変更しても，設定が無効になる．
