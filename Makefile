dest = $$XDG_DATA_HOME/abrechnomat_bot

build:
	mkdir -p $(dest)
	podman run \
		-e MIX_ENV=prod \
		--mount type=bind,source=./,target=/app \
		--mount type=bind,source=$(dest),target=/rel \
		--workdir=/app \
		docker.io/elixir:1.17 \
		/bin/bash -c "mix deps.get --only $MIX_ENV && mix release --overwrite --path /rel"

service:
	mkdir -p ~/.config/systemd/user

	cp -n ./systemd/abrechnomat_bot.env $$XDG_CONFIG_HOME/abrechnomat_bot || true
	chmod 640 $$XDG_CONFIG_HOME/abrechnomat_bot

	install --mode=664 \
		./systemd/abrechnomat_bot.service \
		$$XDG_CONFIG_HOME/systemd/user/

	systemctl --user daemon-reload
	systemctl --user enable abrechnomat_bot.service

	echo "Do not forget allow running the service without login: loginctl enable-linger"
	echo "Restart whenever you're ready: systemctl restart abrechnomat_bot.service"
