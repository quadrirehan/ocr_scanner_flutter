# Flutter OCR Document Scanner

A Flutter application built to scan and extract structured data from credit/debit cards and bank passbooks. It features a custom manual parsing engine to handle noisy OCR data.

## Environment Details
* **Flutter SDK:** v3.38.5
* **Dart SDK:** v3.10.4

## Steps to Run the Project
1. Ensure you have the Flutter SDK installed and configured.
2. Connect a physical Android device to your computer (a physical device is highly recommended over an emulator to properly test the camera hardware).
3. Clone this repository and open the project directory in your terminal.
4. Run `flutter pub get` to install all dependencies.
5. Run `flutter run` to launch the application on your connected device.

## Libraries Used
* **`camera` (^0.10.5+9):** Used to access the device's hardware camera and capture high-resolution images for the card scanner.
* **`image_picker` (^1.1.2):** Used to fulfill the requirement of allowing image uploads from the device gallery for passbooks.
* **`google_mlkit_text_recognition` (^0.12.0):** Used strictly as a raw OCR engine to extract unformatted text blocks from images entirely offline. 
* **`flutter_riverpod` (^2.4.9):** Used for robust state management to cleanly separate the camera lifecycle, asynchronous OCR processing state, and UI updates.

## Assumptions Made
* **Android-First Focus:** Per the assignment guidelines stating Android is mandatory and iOS is optional, hardware permissions and configurations were strictly optimized for the Android `AndroidManifest.xml`.
* **Strict Manual Parsing:** I assumed the restriction "must NOT use any library for parsing extracted data" applied strictly to the logical extraction phase. ML Kit was used purely to get a raw string of text from the image, while all data extraction (Regex for numbers/dates, Luhn algorithm validation) was implemented manually from scratch.
* **Name Extraction Heuristics:** Since standard OCR provides noisy text, I assumed heuristic rules would be acceptable for name extraction. The card parser looks for capitalized strings ignoring standard bank keywords (e.g., "VISA", "VALID THRU"), and the passbook parser searches for specific prefixes (e.g., "NAME", "MR.", "MRS.").
* **Passbook Account Number Logic:** To avoid grabbing phone numbers or branch codes from a passbook, I assumed the longest continuous string of numbers between 9 and 18 digits on the document would represent the core account number.

## What Was Skipped and Why
* **iOS Configuration:** Skipped entirely to focus on delivering a robust, high-quality Android implementation within the strict 3-4 hour time limit.
* **Automated Edge Detection / Smart Cropping:** Rather than building a custom camera overlay that auto-detects document borders (which is highly time-consuming), I skipped this to prioritize the 40% grading weight given to the manual parsing logic, OCR integration, and error handling.