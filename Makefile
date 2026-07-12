.PHONY: setup doctor format check secret-scan hooks test analyze build-staging

setup:
	bash scripts/bootstrap.sh

doctor:
	bash scripts/doctor.sh

format:
	bash scripts/format.sh

check:
	bash scripts/check.sh

secret-scan:
	bash scripts/secret-scan.sh

hooks:
	bash scripts/setup-hooks.sh

test:
	@source scripts/_fvm.sh && $$FLUTTER_CMD test --reporter compact

analyze:
	@source scripts/_fvm.sh && $$FLUTTER_CMD analyze

build-staging:
	@source scripts/_fvm.sh && $$FLUTTER_CMD build apk --debug --flavor staging -t lib/main_staging.dart
