install:
	cp -n ./abrechnomat_bot.env /etc/abrechnomat_bot || true
	chmod 640 /etc/abrechnomat_bot

	install --mode=664 ./abrechnomat_bot.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable abrechnomat_bot.service
	echo "Restart whenever you're ready: systemctl restart abrechnomat_bot.service"
