# 🤖 Chatbot DSA Mentor

A **Flutter-based mobile app** designed to help students master **Data Structures and Algorithms (DSA)** with a built-in **AI-powered mentor chatbot**.  
This project combines **real-time guidance**, **progress tracking**, and **discussion features**, making it an interactive learning tool for developers preparing for interviews or competitive programming.

---

## 🚀 Features

### ✅ **1. AI-Powered DSA Chatbot**
- Integrated with **Groq AI API** (easily extendable to OpenAI or Gemini).
- Users can ask **DSA doubts**, get **step-by-step explanations**, and receive **optimized solutions**.
- Explains **time and space complexities** for all queries.

### ✅ **2. DSA Progress Tracker**
- Tracks solved questions and updates:
  - `solvedCount` – total questions solved.
  - `solvedQuestions` – list of solved titles.
- Stores detailed solutions under:
- Displays solved questions & progress stats on the **DSA Progress screen**.

### ✅ **3. Community Discussion Tab**
- Similar to **Telegram-style group chats**.
- Users can **discuss DSA problems** and **share files**.
- File uploads handled via **Supabase Storage** (`chat-files` bucket).

### ✅ **4. File Upload & Sharing**
- Users can send:
- 📄 PDFs  
- 🖼 Images  
- 📜 Code snippets  
- Files stored securely on Supabase.

### ✅ **5. Secure Authentication**
- **Firebase Authentication** (Google Sign-In / Email & Password).
- Auto-login with **secure token refresh**.

---

## 🛠 Tech Stack

### **Frontend**
- [Flutter](https://flutter.dev/) – cross-platform framework.
- **Riverpod** – state management.
- **GoRouter** – navigation.

### **Backend & Storage**
- [Firebase Auth](https://firebase.google.com/products/auth) – user authentication.
- [Firebase Firestore](https://firebase.google.com/products/firestore) – real-time database.
- [Supabase](https://supabase.io/) – file storage for chat media.

### **AI Integration**
- Groq AI API (with flexibility to swap to OpenAI or Gemini).

---


✅ **Clean Architecture** with modular features for scalability and maintainability.

---

## ⚙️ Setup Instructions

### 🔧 **1. Clone the Repository**
```bash
git clone https://github.com/Arjunyadavsoma/AlgoMentor.git
cd AlgoMentor

```bash


👨‍💻 Author
Soma Arjun Yadav
📧 arjunyadav35763@gmail.com




