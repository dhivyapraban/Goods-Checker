# ECOLOGY

ECOLOGY is a workspace that contains a Flutter mobile application and a separate CNN model training script.

## Repository Layout

- `app/` - Flutter app source code, platform projects, assets, and tests
- `CNN_model/` - Python training code for the computer vision model
- `LICENSE` - Project license

## App

The Flutter app lives in `app/` and includes:

- `lib/` for application code, screens, widgets, providers, services, and models
- `android/`, `ios/`, `web/`, `linux/`, and `macos/` platform folders
- `test/` for widget tests

## Model Training

The `CNN_model/` folder contains `training.py`, which appears to be the entry point for model training.

## Notes

- The workspace currently contains client-side configuration values and platform API key placeholders. Keep real secrets out of source control and load them from secure environment-specific storage.
- If you add environment files or generated artifacts, make sure they are ignored appropriately.
