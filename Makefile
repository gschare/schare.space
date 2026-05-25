default:
	racket site.rkt

clean:
	[ -e docs/ ] && rm -r docs/ || true
