# TBcure — Offline Tuberculosis Detection App (Federated Learning + TFLite)

**TBcure** is a mobile-first, privacy-first Tuberculosis (TB) screening application that performs **offline** TB detection from chest X-ray images using a TensorFlow Lite model trained/updated via Federated Learning. The app is built with **Flutter** for Android, contains a Doctor & Patient dual-login, encrypted local storage, PDF report generation, emergency alert features, and an offline TFLite inference engine.  

> Project documentation: GPCU project brief and invention/patent document (design, features, and specs). :contentReference[oaicite:0]{index=0} :contentReference[oaicite:1]{index=1}

---

## Table of Contents

- [Demo](#demo)  
- [Key Features](#key-features)  
- [System Architecture](#system-architecture)  
- [Model & Federated Learning Overview](#model--federated-learning-overview)  
- [Getting Started (Install & Run)](#getting-started-install--run)  
  - [Prerequisites](#prerequisites)  
  - [Local Setup (Flutter)](#local-setup-flutter)  
  - [Running the App](#running-the-app)  
- [Project Structure](#project-structure)  
- [Usage Guide](#usage-guide)  
  - [Patient Flow](#patient-flow)  
  - [Doctor Flow](#doctor-flow)  
- [API / Backend (Optional)](#api--backend-optional)  
- [Model Training & FL Notes](#model-training--fl-notes)  
- [Testing](#testing)  
- [Security & Privacy](#security--privacy)  
- [Limitations](#limitations)  
- [Future Enhancements](#future-enhancements)  
- [Contributing](#contributing)  
- [License & Credits](#license--credits)  
- [References](#references)

---

## Demo
*(Add screenshots or link to a demo APK / Play store link here)*

---

## Key Features

- Offline TB detection using an embedded **TFLite** model.  
- Dual user roles: **Doctor** and **Patient**.  
- Image upload (camera/gallery), preprocessing, and local inference.  
- PDF report generation and local encrypted storage.  
- Emergency contact trigger for TB-positive predictions.  
- Optional backend (PHP/MySQL or Flask) for federated training coordination and auth.  
- Designed and optimized for low-end Android devices.  

---

## System Architecture

[ Flutter App (Android) ]
├─ UI: Doctor / Patient dashboards
├─ Image preprocessing (resize, normalize)
├─ TFLite Inference Engine (embedded .tflite)
├─ Local encrypted DB / file storage
├─ Report generator (PDF)
└─ Emergency / Notifications module

Optional:
[ Backend (Flask/PHP + MySQL) ] <-- used only for federated training coordination, auth (optional)
[ Federated Learning Coordinator ] <-- receives encrypted model updates, aggregates, returns global model

pgsql
Copy code

Key design goals: **privacy**, **offline capability**, **lightweight**, **usability**. See detailed design and specs in project docs. :contentReference[oaicite:2]{index=2}

---

## Model & Federated Learning Overview

- **On-device inference**: Model exported as `.tflite` (quantized/optimized) for fast inference on mobile CPU.  
- **Federated Learning (FL)**: Training occurs across edge devices (clinic devices) — only model updates/gradients are shared (encrypted) to the coordinator; raw images never leave devices. (FL component is optional and can be enabled when connectivity and privacy agreements are in place.) Details and claims in the project patent/doc. :contentReference[oaicite:3]{index=3}

Model metrics (example):
- Input size: `224x224` (or as used in preprocessing)  
- Output: `TB Detected` / `No TB Detected` + confidence score  
- Latency: < 1s on mid-range Android (varies with device)

---

## Getting Started (Install & Run)

> The app is built with Flutter (Android). Follow these steps to run locally and build the APK / AAB.

### Prerequisites

- Flutter SDK (stable) — see https://flutter.dev  
- Android SDK & Android Studio / VSCode  
- Java 11+ (for Gradle)  
- (Optional) Python & Flask if using optional backend  
- (Optional) `adb` to install/debug on device

### Local Setup (Flutter)

```bash
# clone the repo
git clone https://github.com/<your-username>/tbcure.git
cd tbcure

# install packages
flutter pub get

# ensure Android emulator/device connected
flutter devices
Running the App
bash
Copy code
# debug on connected device
flutter run --release

# build Android AppBundle (AAB)
flutter build appbundle

# build APK (for quick testing)
flutter build apk --release
If you use CI/CD (GitHub Actions), create secrets for signing keys and add build workflow.

Project Structure
bash
Copy code
/tbcure
├─ /android
├─ /ios
├─ /lib
│   ├─ main.dart
│   ├─ /screens
│   │   ├─ login_screen.dart
│   │   ├─ doctor_dashboard.dart
│   │   ├─ patient_dashboard.dart
│   │   ├─ upload_xray.dart
│   │   └─ prediction_result.dart
│   ├─ /services
│   │   ├─ tflite_service.dart
│   │   ├─ image_preprocess.dart
│   │   └─ pdf_report.dart
│   ├─ /models
│   │   └─ user.dart
│   └─ /utils
│       └─ encryption_storage.dart
├─ /assets
│   ├─ model.tflite
│   └─ icons...
├─ /backend (optional)
│   ├─ flask_server.py
│   └─ mysql_init.sql
├─ README.md
└─ LICENSE
Change this structure to match your repo; commit the model.tflite or provide download instructions if too large.

Usage Guide
Patient Flow
Open TBcure and choose Patient login.

Upload or capture chest X-ray (camera/gallery).

App performs local preprocessing and runs the TFLite model.

Result appears: TB Detected / No TB Detected + confidence.

Download or save the PDF report locally.

If TB detected, you can call the emergency contact instantly.

Doctor Flow
Login as Doctor.

View patient list and scheduled appointments.

Open a patient record to view X-ray history and latest predictions.

Approve, add notes, and download reports.

Get notifications when patients upload new images or when high-risk predictions occur.

Screens in /lib/screens show example implementations.

API / Backend (Optional)
TBcure works fully offline. If you want to enable federated training coordination or centralized auth, an optional backend is provided:

Flask API endpoints:

POST /auth/login — (optional) authenticate doctor/patient

POST /fl_update — receive encrypted model updates

GET /global_model — download aggregated global model

Sample backend in /backend (not required for basic offline operation). See backend/README.md for setup.

Model Training & FL Notes
The repo includes the pre-converted TFLite model for inference. Training is performed offline on servers / research environment, and Federated Learning is used to aggregate updates when devices opt-in.

Training pipeline (research):

Data preprocessing & augmentation (chest X-rays)

Train server-side Keras models (for baseline)

Convert to .tflite using TensorFlow Lite converter & quantize

Deploy .tflite into app assets

Federated Learning (high-level):

Devices run local training on device-specific (private) data (if available) and compute model deltas.

Only encrypted gradients/deltas sent to server (never raw images).

Server aggregates deltas (secure aggregation) and returns updated global model.

Device replaces local .tflite with updated weights (after verification).

Note: FL requires secure aggregation, strong privacy policies, and ethical approval when using real patient data. Always follow local regulations / IRB guidelines.

Testing
Unit tests: run flutter test (add tests in /test)

Manual tests: test image upload, prediction, report generation, emergency call flow

Device compatibility: test on multiple Android devices (low-end to high-end)

Model validation: maintain a small validation dataset for regression testing

Add test cases and results as part of your project submission.

Security & Privacy
All medical images and reports are stored locally.

Use secure, OS-backed encryption for stored files (example: use Flutter plugins for secure storage or SQLCipher).

No default cloud uploads — enable server features only with explicit consent.

Follow ISO/IEC 27001 principles and healthcare data governance best practices. See project docs for standards and claims. 
GPCU-192224108.


Limitations
Model accuracy depends on input X-ray quality and preprocessing.

FL orchestration requires network connectivity and a secure aggregator.

No multi-disease classification in the current release.

Not a certified medical device — acts as a decision support tool; clinical confirmation needed.

Future Enhancements
Multi-disease detection (Pneumonia, lung nodules)

Secure federated aggregation with differential privacy

Cloud dashboard for hospital administrators (opt-in)

Biometric login and stronger auth (OTP / 2FA)

Multi-language support and accessibility features

Contributing
Fork the repository

Create a feature branch: git checkout -b feature/<feature-name>

Commit changes: git commit -m "Add <feature>"

Push: git push origin feature/<feature-name>

Create a Pull Request

Please include unit tests and documentation for non-trivial changes.

License & Credits
This repository is released under the MIT License. See LICENSE file.

Primary developer: Deepak Reddy M (or your name)

Advisors / Reviewers: (add names)

Model & research references credited in the REFERENCES section.

References
Project design & executive summary: GPCU — Tuberculosis Detection Application Using Federated Learning. 
GPCU-192224108.


Invention / specification document: Tuberculosis Detection Application Using Federated Learning Model (patent-style). 
192224108-Deepak Patient


TensorFlow Lite documentation — https://www.tensorflow.org/lite

Flutter documentation — https://flutter.dev

Notes / TODO (repo owner)
Add model.tflite or provide secured download link (LFS recommended for large files).

Add signed APK / AAB artifacts to Releases (if allowed).

Add backend/README.md if enabling FL coordinator.

Ensure compliance with your university / ethics board before deploying with real patient data.

