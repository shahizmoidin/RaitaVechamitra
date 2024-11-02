
# 🌾 Raita Vechamitra

**Raita Vechamitra** is a comprehensive Flutter application designed to assist farmers in Karnataka with their agricultural activities. The app allows users to manage income and expenses, track weather conditions, receive health reminders, and access government schemes and subsidies. The primary goal is to help farmers organize their farming activities, enhance productivity, and improve their well-being.

## 🌟 Features

- **Income & Expense Management:**  
  Track and categorize farming-related income and expenses with intuitive forms and charts.

- **Weather Forecasting:**  
  Get real-time weather updates using OpenWeatherAPI to help farmers plan their activities.

- **Health Reminders:**  
  Receive weekly health-related notifications with do's and don’ts for better healthcare.

- **Government Schemes & Subsidies:**  
  Explore various government schemes and subsidies available for farmers.

- **Authentication:**  
  Secure login and registration using Firebase Authentication, along with personalized greetings on the home screen.

- **Charts & Analytics:**  
  Visualize income and expense data through interactive charts (pie, line, etc.) using `fl_chart` for better decision-making.

## 🛠️ Technologies Used

- **Flutter:** Front-end development
- **Firebase Firestore:** Real-time database for managing user data and payments
- **Firebase Authentication:** Secure user login and registration
- **Riverpod:** State management for a seamless user experience
- **OpenWeatherAPI:** Real-time weather forecasting
- **fl_chart:** Visualizing income and expense data
- **Path Provider:** File system paths for exporting CSV and generating PDF reports
- **Printing:** PDF report generation and sharing
- **CSV Export:** Export payment data in CSV format

## 🚀 Installation

To run **Raita Vechamitra** locally, follow these steps:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/raitavechamitra.git
   ```

2. **Navigate to the project directory:**

   ```bash
   cd raitavechamitra
   ```

3. **Install dependencies:**

   ```bash
   flutter pub get
   ```

4. **Run the app:**

   ```bash
   flutter run
   ```

