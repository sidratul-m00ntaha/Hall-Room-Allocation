# 🏨 Hall Room Allocation System

A terminal-based room allocation management system built with **Bash scripting**. Designed to simulate a simplified hostel management workflow for students and provosts.

---

## ✨ Features

### 🧑‍🏫 Provost Panel
- Secure login using stored credentials
- Add, delete, and view rooms
- View student-room allocations
- Approve pending student room requests

### 🎓 Student Panel
- Register as a student (with ID, name, contact)
- Log in using Student ID
- View available rooms and slots
- Apply for room allocation
- View confirmed room assignment

---

## 📁 Project Structure

hall_management.sh # Main script
rooms.txt # Room data (RoomNo:Capacity:Type)
students.txt # Student data (ID:Name:Contact)
allocations.txt # Confirmed room allocations (ID:RoomNo)
pending_requests.txt # Unapproved room requests (ID:RoomNo)
provost_credentials.txt # Provost login credentials (Username:Password)

yaml
Copy
Edit

---

## 🚀 How to Run

chmod +x hall_management.sh
./hall_management.sh

Make sure all the .txt files are in the same directory as hall_management.sh.

🔐 Provost Credentials
You can customize the provost username and password in:

provost_credentials.txt
Default format:

makefile
provost:1234

🛠️ Technologies Used
Shell scripting

Text file-based data handling (no external dependencies)

Linux CLI environment

