#!/bin/bash

# Check for interactive terminal
if [[ ! -t 0 ]]; then
    echo "WARNING: Script not running in an interactive terminal. 'read' prompts may not work as expected!"
fi


# File paths
ROOM_FILE="rooms.txt"
STUDENT_FILE="students.txt"
ALLOC_FILE="allocations.txt"
PENDING_FILE="pending_requests.txt"
PROVOST_CRED="provost_credentials.txt"

main_menu() {
    while true; do
        echo "------------------------"
        echo " Hostel Room Allocation"
        echo "------------------------"
        echo "1. Provost Login"
        echo "2. Student Panel"
        echo "3. Exit"
        read -p "Choose an option: " choice
        case $choice in
            1) provost_login ;;
            2) student_menu ;;
            3) echo "Exiting..."; exit ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

# Provost Section

provost_login() {
    read -p "Enter Provost Username: " username
    read -s -p "Enter Provost Password: " password
    echo
    if grep -q "$username:$password" "$PROVOST_CRED"; then
        echo "Login successful."
        provost_menu
    else
        echo "Invalid credentials."
    fi
}

provost_menu() {
    while true; do
        echo "------ Provost Panel ------"
        echo "1. Add Room"
        echo "2. View All Rooms"
        echo "3. Delete Room"
        echo "4. View Allocations"
        echo "5. Approve Pending Requests"
        echo "6. Logout"
        read -p "Choose an option: " choice
        case $choice in
            1) add_room ;;
            2) view_rooms ;;
            3) delete_room ;;
            4) view_allocations ;;
            5) approve_requests ;;
            6) break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

add_room() {
    read -p "Enter Room Number: " number
    read -p "Enter Capacity: " capacity
    echo "Select Room Type:"
    echo "1. Gonoroom"
    echo "2. Non-Gonoroom"
    read -p "Choice: " type_choice
    case $type_choice in
        1) type="Gonoroom" ;;
        2) type="Non-Gonoroom" ;;
        *) echo "Invalid type."; return ;;
    esac
    echo "$number:$capacity:$type" >> "$ROOM_FILE"
    echo "Room added."
}

view_rooms() {
    echo "---- Available Rooms ----"
    if [ ! -s "$ROOM_FILE" ]; then
        echo "No rooms found."
        return
    fi
    while IFS=: read -r number capacity type; do
        allocated=$(grep -c ":$number\$" "$ALLOC_FILE")
        echo "Room $number | Type: $type | Capacity: $capacity | Allocated: $allocated"
    done < "$ROOM_FILE"
}

delete_room() {
    read -p "Enter Room Number to Delete: " number
    if grep -q "^$number:" "$ROOM_FILE"; then
        grep -v "^$number:" "$ROOM_FILE" > temp && mv temp "$ROOM_FILE"
        grep -v ":$number$" "$ALLOC_FILE" > temp && mv temp "$ALLOC_FILE"
        grep -v ":$number$" "$PENDING_FILE" > temp && mv temp "$PENDING_FILE"
        echo "Room $number deleted."
    else
        echo "Room not found."
    fi
}

view_allocations() {
    echo "--- Confirmed Allocations ---"
    if [ ! -s "$ALLOC_FILE" ]; then
        echo "No allocations found."
        return
    fi
    while IFS=: read -r sid room; do
        name=$(grep "^$sid:" "$STUDENT_FILE" | cut -d: -f2)
        echo "Student ID: $sid | Name: $name | Room: $room"
    done < "$ALLOC_FILE"
}

approve_requests() {
    echo "--- Pending Room Requests ---"
    if [ ! -s "$PENDING_FILE" ]; then
        echo "No pending requests."
        return
    fi

    # Save stdin to fd 3 for interactive reads
exec 3<&0

while IFS=: read -r sid room; do
    name=$(grep "^$sid:" "$STUDENT_FILE" | cut -d: -f2)
    [ -z "$name" ] && name="Unknown"

    echo "Student ID: $sid | Name: $name | Requested Room: $room"
    echo -n "Approve this request? (y/n): "
    read -u 3 confirm

    if [[ "$confirm" == "y" ]]; then
        capacity=$(grep "^$room:" "$ROOM_FILE" | cut -d: -f2)
        [ -z "$capacity" ] && echo "Room $room not found. Skipping." && continue
        allocated=$(grep -c ":$room\$" "$ALLOC_FILE")
        if (( allocated < capacity )); then
            echo "$sid:$room" >> "$ALLOC_FILE"
            echo "Approved."
        else
            echo "Room full. Cannot approve."
        fi
    else
        echo "Request skipped."
    fi
done < "$PENDING_FILE"

# Clear the file after processing
> "$PENDING_FILE"
echo "All requests processed."

}

# Student Section

student_menu() {
    while true; do
        echo "------ Student Panel ------"
        echo "1. Register"
        echo "2. Login"
        echo "3. Back to Main Menu"
        read -p "Choose an option: " choice
        case $choice in
            1) student_register ;;
            2) student_login ;;
            3) break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

student_register() {
    read -p "Enter Student ID: " sid
    if grep -q "^$sid:" "$STUDENT_FILE"; then
        echo "Student already registered."
        return
    fi
    read -p "Enter Name: " name
    read -p "Enter Contact: " contact
    echo "$sid:$name:$contact" >> "$STUDENT_FILE"
    echo "Registration successful."
}

student_login() {
    read -p "Enter Student ID: " sid
    if ! grep -q "^$sid:" "$STUDENT_FILE"; then
        echo "Student not registered."
        return
    fi
    student_dashboard "$sid"
}

student_dashboard() {
    sid="$1"
    while true; do
        echo "--- Student Dashboard (ID: $sid) ---"
        echo "1. View Available Rooms"
        echo "2. Apply for Room"
        echo "3. View My Allocation"
        echo "4. Logout"
        read -p "Choose an option: " choice
        case $choice in
            1) view_available_rooms ;;
            2) apply_room "$sid" ;;
            3) view_my_allocation "$sid" ;;
            4) break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

view_available_rooms() {
    echo "--- Available Rooms ---"
    while IFS=: read -r number capacity type; do
        allocated=$(grep -c ":$number\$" "$ALLOC_FILE")
        if (( allocated < capacity )); then
            echo "Room $number | Type: $type | Available Slots: $((capacity - allocated))"
        fi
    done < "$ROOM_FILE"
}

apply_room() {
    sid="$1"
    if grep -q "^$sid:" "$ALLOC_FILE"; then
        echo "Already allocated a room."
        return
    fi
    if grep -q "^$sid:" "$PENDING_FILE"; then
        echo "You already have a pending request."
        return
    fi
    read -p "Enter Desired Room Number: " room
    if ! grep -q "^$room:" "$ROOM_FILE"; then
        echo "Room not found."
        return
    fi
    echo "$sid:$room" >> "$PENDING_FILE"
    echo "Room request submitted for approval."
}

view_my_allocation() {
    sid="$1"
    if grep -q "^$sid:" "$ALLOC_FILE"; then
        room=$(grep "^$sid:" "$ALLOC_FILE" | cut -d: -f2)
        echo "You are allocated to Room: $room"
    else
        echo "No confirmed allocation found."
    fi
}

# Start
main_menu
