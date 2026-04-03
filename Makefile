# Global Music Map — Environment Runner
# Usage:
#   make dev          → run on connected device (DEV)
#   make uat          → run on connected device (UAT)
#   make prod         → run on connected device (PROD)
#   make build-uat    → build release IPA/APK for UAT
#   make build-prod   → build release IPA/APK for PROD
#   make gen          → run code generation (freezed, riverpod)
#   make clean        → flutter clean + pod deintegrate

FLUTTER = flutter
ENV_DIR = env

.PHONY: dev uat prod build-uat build-prod gen clean setup check-env

# ── Development ──────────────────────────────────────────────────────────────

dev: check-env-dev
	FLUTTER_XCODE_CODE_SIGN_IDENTITY=- \
	FLUTTER_XCODE_CODE_SIGNING_REQUIRED=NO \
	FLUTTER_XCODE_AD_HOC_CODE_SIGNING_ALLOWED=YES \
	$(FLUTTER) run --dart-define-from-file=$(ENV_DIR)/dev.json

dev-ios: check-env-dev
	FLUTTER_XCODE_CODE_SIGN_IDENTITY=- \
	FLUTTER_XCODE_CODE_SIGNING_REQUIRED=NO \
	FLUTTER_XCODE_AD_HOC_CODE_SIGNING_ALLOWED=YES \
	$(FLUTTER) run -d iPhone --dart-define-from-file=$(ENV_DIR)/dev.json

dev-android: check-env-dev
	$(FLUTTER) run -d emulator --dart-define-from-file=$(ENV_DIR)/dev.json

# ── UAT ──────────────────────────────────────────────────────────────────────

uat: check-env-uat
	$(FLUTTER) run --dart-define-from-file=$(ENV_DIR)/uat.json

build-uat-ios: check-env-uat
	$(FLUTTER) build ipa \
		--dart-define-from-file=$(ENV_DIR)/uat.json \
		--export-options-plist=ios/ExportOptions-uat.plist

build-uat-android: check-env-uat
	$(FLUTTER) build apk \
		--release \
		--dart-define-from-file=$(ENV_DIR)/uat.json

# ── Production ───────────────────────────────────────────────────────────────

prod: check-env-prod
	$(FLUTTER) run --release --dart-define-from-file=$(ENV_DIR)/prod.json

build-prod-ios: check-env-prod
	$(FLUTTER) build ipa \
		--dart-define-from-file=$(ENV_DIR)/prod.json \
		--export-options-plist=ios/ExportOptions-prod.plist

build-prod-android: check-env-prod
	$(FLUTTER) build appbundle \
		--release \
		--dart-define-from-file=$(ENV_DIR)/prod.json

# ── Code Generation ───────────────────────────────────────────────────────────

gen:
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs

gen-watch:
	$(FLUTTER) pub run build_runner watch --delete-conflicting-outputs

# ── Setup & Utilities ─────────────────────────────────────────────────────────

setup:
	@echo "Copying example env files — fill in your real tokens before running"
	cp -n $(ENV_DIR)/dev.json.example $(ENV_DIR)/dev.json || true
	cp -n $(ENV_DIR)/uat.json.example $(ENV_DIR)/uat.json || true
	cp -n $(ENV_DIR)/prod.json.example $(ENV_DIR)/prod.json || true
	$(FLUTTER) pub get
	cd ios && pod install

clean:
	$(FLUTTER) clean
	cd ios && pod deintegrate && pod cache clean --all
	rm -rf ios/Pods ios/Podfile.lock

# ── Guards ────────────────────────────────────────────────────────────────────

check-env-dev:
	@test -f $(ENV_DIR)/dev.json || (echo "ERROR: env/dev.json not found. Run 'make setup' first." && exit 1)

check-env-uat:
	@test -f $(ENV_DIR)/uat.json || (echo "ERROR: env/uat.json not found. Run 'make setup' first." && exit 1)

check-env-prod:
	@test -f $(ENV_DIR)/prod.json || (echo "ERROR: env/prod.json not found. Run 'make setup' first." && exit 1)
