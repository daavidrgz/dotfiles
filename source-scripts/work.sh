work() {
	bspc rule -a "Code" desktop='^2'
	bspc rule -a "Chromium" desktop='^3'
	bspc rule -a "firefox" desktop='^4'

	z $1
	CURRENT_DIR=${PWD##*/}

	code . &>/dev/null &
	chromium "https://bitbucket.org/trileuco/$CURRENT_DIR" &>/dev/null &
	firefox "https://redmine.trileuco.com" "https://im.trileuco.com" \
		"https://mail.google.com/mail/u/1" "https://meet.google.com/exp-gwvd-vvs" &>/dev/null &

	sleep 2
	bspc rule -a "Code" desktop='^'
	bspc rule -a "Chromium" desktop='^'
	bspc rule -a "firefox" desktop='^'
}
