# Tennis

Scrap ATP and Wikipedia to collect tennis players' information

## NOTES

Edit crontab

crontab -l > /tmp/crontab && vi /tmp/crontab && crontab /tmp/crontab

Debug

/usr/local/lib/ruby/gems/2.7.0/gems/ruby-debug-ide-0.7.2/bin/rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 lib/scrap-rank-history.rb

ruby -rjson -ryaml -e "puts JSON.pretty_generate(YAML.load_file(ARGV[0]))" test.yaml
