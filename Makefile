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
	flutter test --reporter compact

analyze:
	flutter analyze

build-staging:
	flutter build apk --debug --flavor staging -t lib/main_staging.dart
