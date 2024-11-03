dest = /opt/abrechnomat_bot

install:
	podman run \
		-e MIX_ENV=prod \
		--mount type=bind,source=./,target=/app \
		--mount type=bind,source=$(dest),target=/rel \
		--workdir=/app \
		docker.io/elixir:1.17 \
		/bin/bash -c "mix deps.get --only $MIX_ENV && mix release --overwrite --path /rel"

service:
	cp -n ./systemd/abrechnomat_bot.env /etc/abrechnomat_bot || true
	chmod 640 /etc/abrechnomat_bot

	install --mode=664 \
		./systemd/abrechnomat_bot.service \
		/etc/systemd/system/

	systemctl daemon-reload
	systemctl enable abrechnomat_bot.service

	echo "Restart whenever you're ready: systemctl restart abrechnomat_bot.service"
