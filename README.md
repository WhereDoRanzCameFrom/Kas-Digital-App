# 💸 Kas Digital - Digital Financial Recording App

Kas Digital is a modern, real-time financial tracking and digital bookkeeping application built using Flutter and powered by Firebase. It allows organizations and group projects to manage income, track daily operational expenses, manage contributions, and generate instant financial reports seamlessly.

# *Some of this project's code is kept in a private repository for security and copyright reasons.*

## 🚀 Key Features Overview

# 📈 Transaction & Cashflow Management
# - Income & Expense Tracking: Record daily financial transactions systematically with custom categories and descriptions.
# - Contribution & Deposit Logs: Dedicated feature to track and log incoming funds and member contributions.
# - History & Search: Easily browse and review past transaction records using intuitive filtering options.

# 🔐 Security & Authentication
# - Secure Authentication: Firebase-backed user login system with integrated local authentication services for additional access protection.

# 📊 Analytics & Reporting
# - Interactive Charts: Visualize cash flow trends and financial distributions using responsive chart visualizations (`fl_chart`).
# - Document Exporting: Generate and export comprehensive financial reports into professional **PDF** files or **Excel** spreadsheets for easy sharing.

---

## 🛠️ Tech Stack & Dependencies

Built using the following technology stack and Flutter packages:

- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.3.0`)
- **Backend & Database:** [Firebase Core](https://pub.dev/packages/firebase_core) & [Cloud Firestore](https://pub.dev/packages/cloud_firestore)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Routing:** [Go Router](https://pub.dev/packages/go_router)
- **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Visualization & Utilities:**
  - Data Visualization: `fl_chart`
  - Date & Number Formatting: `intl`
  - PDF & Spreadsheet Generation: `pdf` & `excel`
  - File Utilities & Sharing: `path_provider` & `share_plus`
  - Encryption & Permissions: `permission_handler`, `crypto`

---

## ⚙️ Getting Started & Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine (version 3.3.0 or higher).
- An active Android Emulator, iOS Simulator, or connected physical device.
- A configured [Firebase Console](https://console.firebase.google.com/) project.

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/kas-digitar.git](https://github.com/your-username/kas-digitar.git)
   cd kas-digitar
