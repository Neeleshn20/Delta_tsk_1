#!/bin/bash


function genStudent() {

  # If a file is provided, use it to create student accounts
  if [ -f studentDetails.txt ]; then
    while read -r name roll hostel room preferences allocatedMess month department; do
      username="Nittrichy$roll"   # Add "Nitt" prefix to the username

      # Check if the user already exists
      if id "$username" &>/dev/null; then
        echo "User '$username' already exists."
      else
        sudo useradd -m -d "/home/$username" "$username"
        sudo mkdir -p "/home/Hostel$hostel/RN$room/$username"
        sudo touch "/home/$username/userDetails.txt"
        echo -e "Name: $name\nRoll Number: $roll\nHostel: $hostel\nRoom: $room\nMonth: $month\nDepartment: $department\nAllocated Mess: $allocatedMess\nMess Preferences: $preferences" | sudo tee "/home/$username/userDetails.txt"
        sudo touch "/home/Hostel$hostel/announcements.txt"
        sudo touch "/home/Hostel$hostel/feeDefaulters.txt"
        sudo touch "/home/Hostel$hostel/RN$room/$username/fees.txt"
        echo "Directories created successfully for user $username"
      fi
    done < studentDetails.txt
  else
    # Prompt for user input to create student accounts
    while true; do
      read -p "Enter student name (or 'exit' to finish): " name
      if [[ $name == "exit" ]]; then
        break
      fi

      read -p "Enter student roll number: " roll
      read -p "Enter student hostel: " hostel
      read -p "Enter student room number: " room
      read -p "Enter mess preferences: " preferences
      read -p "Enter allocated mess: " allocatedMess
      read -p "Enter month: " month
      read -p "Enter department: " department

      username="Nittrichy$roll"   # Add "Nitt" prefix to the username

      # Check if the user already exists
      if id "$username" &>/dev/null; then
        echo "User '$username' already exists."
      else
        sudo useradd -m -d "/home/$username" "$username"
        sudo mkdir -p "/home/Hostel$hostel/RN$room/$username"
        sudo touch "/home/$username/userDetails.txt"
        echo -e "Name: $name\nRoll Number: $roll\nHostel: $hostel\nRoom: $room\nMonth: $month\nDepartment: $department\nAllocated Mess: $allocatedMess\nMess Preferences: $preferences" | sudo tee "/home/$username/userDetails.txt"
        sudo touch "/home/Hostel$hostel/announcements.txt"
        sudo touch "/home/Hostel$hostel/feeDefaulters.txt"
        sudo touch "/home/Hostel$hostel/RN$room/$username/fees.txt"
        echo "Directories created successfully for user $username"
      fi
    done
  fi
}

permit() {
  # Set permissions for student accounts
  while IFS=$'\t' read -r name roll hostel room preferences allocatedMess month department; do
    username="$roll"
    sudo chown "$username:$username" "/home/$username/userDetails.txt"
    sudo chmod 600 "/home/$username/userDetails.txt"
    if [[ -f "/home/$hostel/announcements.txt" ]]; then
      sudo chmod u+r "/home/$hostel/announcements.txt" 2>/dev/null
    fi
    if [[ -f "/home/$hostel/feeDefaulters.txt" ]]; then
      sudo chmod u+r "/home/$hostel/feeDefaulters.txt" 2>/dev/null
    fi
    touch "/home/$username/userDetails.txt"
  done < studentDetails.txt

  # Set permissions for Hostel Wardens
  sudo chmod g+rwx "/home/GarnetA"
  sudo chmod g+rwx "/home/GarnetB"
  sudo chmod g+rwx "/home/Agate"
  sudo chmod g+rwx "/home/Opal"

  # Set permissions for HAD
  sudo chmod u+rwx "/home" "/home/GarnetA" "/home/GarnetB" "/home/Agate" "/home/Opal"
  sudo chmod u+rwx "/home/mess.txt"
}

updateDefaulter() {
  user_name=$(id -un)
  warden_hostel="${user_name: -1}"
  hostels=("GarnetA" "GarnetB" "Agate" "Opal")
  current_hostel="${hostels[$warden_hostel-1]}"
  sudo mkdir -p "/home/$current_hostel"
  sudo touch "/home/$current_hostel/feeDefaulters.txt"
  while IFS= read -r -d '' file; do
    student_roll=${file%/}
    student_roll=${student_roll##*/}
    student_name=$(grep -Po "Name: \K.*" "/home/$current_hostel/$student_roll/userDetails.txt")
    fee_status=$(grep -Po "Month: .*" "/home/$current_hostel/$student_roll/userDetails.txt" | grep -Po "Month: \K.*")
    if [[ "$fee_status" != "Paid" ]]; then
      echo "$student_name, $student_roll" >> "/home/$current_hostel/feeDefaulters.txt"
    fi
  done < <(find "/home/$current_hostel" -name "fees.txt" -print0)
}

messAllocation() {
  user_role=$(id -u)
  if [ "$user_role" == "0" ]; then
    # Superuser (Hostel Office) can allocate messes to all students
    hostels=("GarnetA" "GarnetB" "Agate" "Opal")
    for ((i = 0; i < ${#hostels[@]}; i++)); do
      current_hostel="${hostels[$i]}"
      while IFS= read -r -d '' file; do
        student_roll=${file%/}
        student_roll=${student_roll##*/}
        student_name=$(grep -Po "Name: \K.*" "/home/$current_hostel/$student_roll/userDetails.txt")
        echo "$student_roll" >> "/home/$current_hostel/mess.txt"
        echo "Allocated Mess: $student_name" >> "/home/$current_hostel/$student_roll/userDetails.txt"
      done < <(find "/home/$current_hostel" -name "userDetails.txt" -print0)
    done
  else
    # Student can record their mess preferences
    user_name=$(id -un)
    student_roll="${user_name}"
    read -p "Enter your mess preference order as a numeric sequence: " preferences
    warden_hostel="${student_roll: -1}"
    current_hostel="${hostels[$warden_hostel-1]}"
    echo "Mess Preferences: $preferences" >> "/home/$current_hostel/$student_roll/userDetails.txt"
    echo "$student_roll" >> "/home/$current_hostel/mess.txt"
  fi
  
# Alias - feeBreakup

function feeBreakup() {
  student_roll="${USER}"
  student_home="$HOME"
  fee_breakup_file="/home/neelesh2004/college_server/feeBreakup.txt"

  if [ -f "$fee_breakup_file" ]; then
    while read -r category amount; do
      fees_file="$student_home/fees.txt"
      if grep -q "$category" "$fees_file"; then
        # Update existing category amount
        sed -i "s/^$category:.*/$category:$amount/g" "$fees_file"
      else
        # Add new category amount
        echo "$category:$amount" >> "$fees_file"
      fi
    done < "$fee_breakup_file"
    echo "Payment successful. Fees updated."
  else
    echo "Fee breakup file not found."
  fi
}
}

# Alias - signOut

function signOut() {

  user_name=$(id -un)

  warden_hostel="${roll: -1}"

  read -p "Enter approval from warden to stay out overnight (Y/N): " approval

  if [[ $approval == "Y" || $approval == "y" ]]; then

    read -p "Enter return date (YYYY-MM-DD): " return_date

    echo "Return Date: $return_date" >>/home/"$roll"/userDetails.txt

  else

    echo "Stay out request denied."

  fi

}


# Check command line argument for alias
if [[ $# -eq 0 ]]; then
  echo "No alias provided."
  exit 1
fi

# Execute the corresponding alias
case $1 in
"genStudent")
  genStudent
  ;;
"permit")
  permit
  ;;
"updateDefaulter")
  updateDefaulter
  ;;
"messAllocation")
  messAllocation
  ;;
"feeBreakup")
  feeBreakup
  ;;
"signOut")
  signOut
  ;;
*)
  echo "Invalid alias."
  ;;
esac

