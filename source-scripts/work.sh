_work() {
	bspc rule -a "Code" desktop='^2'
	bspc rule -a "Chromium" desktop='^3'
	bspc rule -a "firefox" desktop='^4'
	bspc rule -a "Alacritty" desktop='^1'

	cd ~/work/yepcode/yepcode-web-client
	code . &>/dev/null &
	chromium &>/dev/null &
	firefox "https://redmine.trileuco.com" "https://im.trileuco.com" "https://mail.google.com/mail/u/1" &>/dev/null &
	alacritty &>/dev/null &

	sleep 2
	bspc rule -a "Code" desktop='^'
	bspc rule -a "Chromium" desktop='^'
	bspc rule -a "firefox" desktop='^'
	bspc rule -a "Alacritty" desktop='^'
}
