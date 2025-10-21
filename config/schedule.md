# Level Change Application Scheduler

## Cron設定

毎月1日の0:00にレベル変更申請を実行するためのcron設定です。

### 本番環境での設定

```bash
# crontabを編集
crontab -e

# 以下の行を追加（毎月1日の0:00に実行）
0 0 1 * * cd /path/to/your/app && RAILS_ENV=production bundle exec rake level_change:execute >> log/level_change.log 2>&1
```

### 開発環境でのテスト

```bash
# 手動実行でテスト
bundle exec rake level_change:execute

# 申請状況確認
bundle exec rake level_change:show_pending
```

### Herokuでの設定

Heroku Schedulerを使用する場合：

1. Heroku Schedulerアドオンを追加
```bash
heroku addons:create scheduler:standard
```

2. スケジューラーを設定
```bash
heroku addons:open scheduler
```

3. 以下のコマンドを毎月1日0:00に実行するよう設定
```bash
rake level_change:execute
```

### Docker環境での設定

docker-compose.ymlにcronサービスを追加：

```yaml
services:
  cron:
    build: .
    command: cron -f
    volumes:
      - .:/app
    environment:
      - RAILS_ENV=production
    depends_on:
      - db
```

Dockerfileにcron設定を追加：

```dockerfile
# crontabファイルをコピー
COPY config/crontab /etc/cron.d/level-change
RUN chmod 0644 /etc/cron.d/level-change
RUN crontab /etc/cron.d/level-change
```

### ログ監視

実行ログは以下の場所に記録されます：
- アプリケーションログ: `log/production.log`
- cron実行ログ: `log/level_change.log`

### 監視とアラート

実行失敗時の通知設定：
1. ログ監視ツールの設定
2. メール通知の設定
3. Slackなどのチャット通知

### トラブルシューティング

よくある問題と解決方法：

1. **環境変数が読み込まれない**
   - crontabで環境変数を明示的に設定
   - `.env`ファイルの読み込み確認

2. **パスが見つからない**
   - フルパスを使用
   - `cd`コマンドでディレクトリ移動

3. **権限エラー**
   - ファイル権限の確認
   - ユーザー権限の確認

4. **データベース接続エラー**
   - データベース設定の確認
   - 接続プールの設定確認