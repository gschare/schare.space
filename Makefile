default:
	[ -e docs/ ] && rm -r docs/ || true
	racket site.rkt
