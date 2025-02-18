#!/bin/bash
Database_Dir="database"


database_creation() {
  echo "Enter the Name of Database"
  read DB_NAME

  if [[ $DB_NAME =~ ^[a-zA-Z] ]]; then
   
    if [ -d "$Database_Dir/$DB_NAME" ]; then
      echo "Database '$DB_NAME' already exists."
    else
      mkdir -p "$Database_Dir/$DB_NAME"
      echo "Database '$DB_NAME' created."
    fi
  else
    echo "The name of the database must start with a letter."
  fi
}


list_databases() {
  echo "These are the available databases:"
  ls -1 "$Database_Dir"
}


database_connection() {
  echo -n "Enter database name: "
  read db_name

 
  

 
  if [ -z "$db_name" ]; then
    echo "Database name cannot be empty."
    return
  fi

 
  if [[ "$db_name" == "/" || "$db_name" == "." || "$db_name" == ".." ]]; then
    echo "Invalid database name: '$db_name'. Cannot connect to system directories."
    return
  fi

  
  if [ -d "$Database_Dir/$db_name" ]; then
    echo "Connected to database '$db_name'."
   
    if [ -f "./table.sh" ]; then
      ./table.sh "$db_name" 
    else
      echo "Error: 'table.sh' script not found."
    fi
  else
    echo "Database '$db_name' not found."
  fi
}


database_deletion() {
  echo -n "Enter database name: "
  read DB_NAME
  if [ -d "$Database_Dir/$DB_NAME" ]; then
    read -p "Confirm deletion (y/n): " confirm
    case "$confirm" in
      y|Y|YES|Yes|yes)
        rm -rf "$Database_Dir/$DB_NAME"
        echo "Database '$DB_NAME' deleted.";;
      n|N|NO|No|no)
        echo "You chose not to delete the database.";;
      *)
        echo "Invalid response.";;
    esac
  else
    echo "Database not found."
  fi
}


main_menu() {
  while true; do
    clear
    echo "Choose an option from the database menu"
    echo "___________________________"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect to Database"
    echo "4. Delete Database"
    echo "5. Exit"
    echo -n "Choose an option: "
    read option
    case $option in
      1) database_creation ;;
      2) list_databases ;;
      3) database_connection ;;
      4) database_deletion ;;
      5) exit ;;
      *) echo "Invalid option." ;;
    esac
    sleep 5
  done
}


main_menu

