data_home = $$HOME/.local/share
config_home= $$HOME/.config
dest = $(data_home)/abrechnomat_bot

build:
	mkdir -p $(dest)
	podman run \
		-e MIX_ENV=prod \
		-e MIX_BUILD_PATH=/build \
		--mount type=bind,source=./,target=/app \
		--mount type=bind,source=$(dest),target=/rel \
		--workdir=/app \
		docker.io/elixir:1.18 \
		/bin/bash -c "mix deps.get --only $$MIX_ENV && mix release --overwrite --path /rel"

service:
	mkdir -p ~/.config/systemd/user

	cp -n ./systemd/abrechnomat_bot.env $(config_home)/abrechnomat_bot || true
	chmod 640 $(config_home)/abrechnomat_bot

	install --mode=664 \
		./systemd/abrechnomat_bot.service \
		$(config_home)/systemd/user/

	systemctl --user daemon-reload
	systemctl --user enable abrechnomat_bot.service

	echo "Do not forget allow running the service without login: loginctl enable-linger"
	echo "Restart whenever you're ready: systemctl restart --user abrechnomat_bot.service"
