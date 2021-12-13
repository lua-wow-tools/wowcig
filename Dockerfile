FROM python:3.10-buster

RUN \
echo deb http://packages.cloud.google.com/apt gcsfuse-buster main | \
tee /etc/apt/sources.list.d/gcsfuse.list && \
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
apt-key add - && \
echo deb http://openresty.org/package/debian buster openresty | \
tee /etc/apt/sources.list.d/openresty.list && \
curl https://openresty.org/package/pubkey.gpg | \
apt-key add - && \
apt-get update && \
apt-get install -y gcsfuse libzip-dev openresty tini && \
apt-get clean && \
python3 -m pip install hererocks && \
hererocks -l 5.1 -r 3.5.0 /usr/local && \
luarocks install wowcig

WORKDIR /opt/wowcig

RUN \
mkdir logs mount && \
ln -s mount/cache && \
ln -s mount/extracts && \
ln -s $PWD/mount/luadbd /root/.cache/luadbd && \
echo '\
daemon off;\n\
error_log /dev/stdout info;\n\
events {\n\
  worker_connections 1024;\n\
}\n\
http {\n\
  access_log /dev/stdout;\n\
  server {\n\
    listen 8080;\n\
    location /wowcig {\n\
      default_type text/plain;\n\
      content_by_lua_block {\n\
        local args = ngx.req.get_uri_args()\n\
        local product = assert(args.product, "missing product")\n\
        local dbargs = ""\n\
        if type(args.db2) == "table" then\n\
          dbargs = " -d " .. table.concat(args.db2, " -d ")\n\
        elseif type(args.db2) == "string" then\n\
          dbargs = " -d " .. args.db2\n\
        end\n\
        os.execute("env HOME=/root /usr/local/bin/wowcig -z -v -p " .. product .. dbargs)\n\
        ngx.say("Successfully extracted " .. product .. ". Have a nice day.")\n\
      }\n\
    }\n\
  }\n\
}\n\
user root;\n\
worker_processes 1;\n\
' > nginx.conf && \
echo '\
set -e\n\
gcsfuse --implicit-dirs wow.ferronn.dev mount\n\
/usr/local/openresty/nginx/sbin/nginx -p . -c nginx.conf\n\
' > run.sh

ENTRYPOINT ["tini", "--", "sh", "run.sh"]
