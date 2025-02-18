#!/bin/bash

DB_NAME=$1
TABLE_DIR="$DB_NAME/tables"


mkdir -p "$TABLE_DIR"


validate_name() {
  local name=$1
  if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
    echo "Invalid name: '$name'. Names must start with a letter and contain only letters, numbers, and underscores."
    return 1
  fi
  if [[ ${#name} -gt 30 ]]; then
    echo "Invalid name: '$name'. Names must not exceed 30 characters."
    return 1
  fi
  return 0
}

#column value

validate_value() {
  local value=$1
  local type=$2
  case $type in
    Integer)
      if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
        echo "Error: Value '$value' is not a valid Integer."
        return 1
      fi
      ;;
    String)
      if [[ "$value" =~ [^a-zA-Z0-9_[:space:]] ]]; then
        echo "Error: Value '$value' contains invalid characters for a String."
        return 1
      fi
      ;;
    *)
      echo "Error: Unsupported data type '$type'."
      return 1
      ;;
  esac
  return 0
}


create_table() {
  while true; do
    echo -n "Enter table name: "
    read table_name
    if [[ -z "$table_name" ]]; then
      echo "Table name cannot be empty. Please try again."
    elif ! validate_name "$table_name"; then
      continue
    else
      break
    fi
  done

  metadata_file="$TABLE_DIR/$table_name.meta"
  data_file="$TABLE_DIR/$table_name.data"

  if [ -f "$metadata_file" ]; then
    echo "Table '$table_name' already exists."
    return
  fi

  while true; do
    echo -n "Enter number of columns: "
    read num_columns
    if ! [[ "$num_columns" =~ ^[0-9]+$ ]] || [ "$num_columns" -le 0 ]; then
      echo "Invalid number of columns. Please enter a positive integer."
    else
      break
    fi
  done

  columns=()
  for ((i = 0; i < num_columns; i++)); do
    while true; do
      echo -n "Enter column $((i+1)) name: "
      read column_name
      if [[ -z "$column_name" ]]; then
        echo "Column name cannot be empty. Please try again."
      elif ! validate_name "$column_name"; then
        continue
      else
        break
      fi
    done

    while true; do
      echo -n "Enter data type for $column_name (Integer or String): "
      read column_type
      if [[ "$column_type" == "Integer" || "$column_type" == "String" ]]; then
        break
      else
        echo "Invalid data type. Only 'Integer' or 'String' are allowed. Please try again."
      fi
    done

    columns+=("$column_name:$column_type")
  done

  # Save column
  echo "${columns[@]}" > "$metadata_file"
  touch "$data_file"
  echo "Table '$table_name' created successfully."
}


insert_row() {
  echo -n "Enter table name: "
  read table_name
  metadata_file="$TABLE_DIR/$table_name.meta"
  data_file="$TABLE_DIR/$table_name.data"

  if [ ! -f "$metadata_file" ]; then
    echo "Table '$table_name' does not exist."
    return
  fi

  
  column_definitions=($(cat "$metadata_file"))
  primary_key_column=$(echo "${column_definitions[0]}" | cut -d':' -f1)
  row_data=""

  # values column
  for column in "${column_definitions[@]}"; do
    column_name=$(echo "$column" | cut -d':' -f1)
    column_type=$(echo "$column" | cut -d':' -f2)
    while true; do
      echo -n "Enter value for $column_name ($column_type): "
      read value
      if validate_value "$value" "$column_type"; then
        break
      fi
    done
    row_data+="$value,"
  done

  primary_key_value=$(echo "$row_data" | cut -d',' -f1)

 
  if grep -q "^$primary_key_value," "$data_file"; then
    echo "Error: Primary key '$primary_key_value' already exists. Row insertion failed."
    return
  fi

  
  echo "${row_data%,}" >> "$data_file"
  echo "Row inserted successfully."
}


delete_row() {
  echo -n "Enter table name: "
  read table_name
  data_file="$TABLE_DIR/$table_name.data"

  if [ ! -f "$data_file" ]; then
    echo "Table '$table_name' does not exist or has no data."
    return
  fi

  echo -n "Enter row number to delete (starting from 1): "
  read row_num

  
  total_lines=$(wc -l < "$data_file")
  if (( row_num < 1 || row_num > total_lines )); then
    echo "Error: Row number $row_num does not exist. Valid range: 1 to $total_lines."
    return
  fi

  
  sed -i "${row_num}d" "$data_file"
  echo "Row number $row_num deleted successfully."
}


update_row() {
  echo -n "Enter table name: "
  read table_name
  metadata_file="$TABLE_DIR/$table_name.meta"
  data_file="$TABLE_DIR/$table_name.data"

  if [ ! -f "$metadata_file" ]; then
    echo "Table '$table_name' does not exist."
    return
  fi

  echo -n "Enter row number to update (starting from 1): "
  read row_num

  column_definitions=($(cat "$metadata_file"))
  current_row=$(sed -n "${row_num}p" "$data_file")
  if [ -z "$current_row" ]; then
    echo "Row number $row_num does not exist."
    return
  fi

  new_row=""
  IFS=',' read -r -a row_values <<< "$current_row"
  for i in "${!column_definitions[@]}"; do
    column_name=$(echo "${column_definitions[$i]}" | cut -d':' -f1)
    column_type=$(echo "${column_definitions[$i]}" | cut -d':' -f2)
    while true; do
      echo -n "Enter new value for $column_name (current: ${row_values[$i]} | $column_type): "
      read new_value
      if validate_value "$new_value" "$column_type"; then
        break
      fi
    done
    new_row+="$new_value,"
  done

  sed -i "${row_num}s/.*/${new_row%,}/" "$data_file"
  echo "Row updated successfully."
}


list_tables() {
  echo "Available tables:"
  ls "$TABLE_DIR" | grep ".meta" | sed 's/.meta//'
}


drop_table() {
  echo -n "Enter table name: "
  read table_name
  metadata_file="$TABLE_DIR/$table_name.meta"
  data_file="$TABLE_DIR/$table_name.data"

  if [ -f "$metadata_file" ]; then
    read -p "Are you sure you want to delete the table '$table_name'? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
      rm -f "$metadata_file" "$data_file"
      echo "Table '$table_name' deleted successfully."
    else
      echo "Deletion canceled."
    fi
  else
    echo "Table '$table_name' does not exist."
  fi
}


show_data() {
  echo -n "Enter table name: "
  read table_name
  metadata_file="$TABLE_DIR/$table_name.meta"
  data_file="$TABLE_DIR/$table_name.data"

  if [ -f "$metadata_file" ]; then
    column_definitions=($(cat "$metadata_file"))
    echo "Table Columns: ${column_definitions[@]}"
    if [ -f "$data_file" ]; then
      cat "$data_file"
    else
      echo "No data found."
    fi
  else
    echo "Table '$table_name' does not exist."
  fi
}


main_menu() {
  while true; do
    echo "Table Management System"
    echo "------------------------"
    echo "1. Create Table"
    echo "2. List Tables"
    echo "3. Drop Table"
    echo "4. Insert Row"
    echo "5. Show Data"
    echo "6. Delete Row"
    echo "7. Update Row11"
    echo "8. Exit"
    echo -n "Choose an option: "
    read option

    case $option in
      1) create_table ;;
      2) list_tables ;;
      3) drop_table ;;
      4) insert_row ;;
      5) show_data ;;
      6) delete_row ;;
      7) update_row ;;
      8) exit ;;
      *) echo "Invalid option." ;;
    esac
    echo
  done
}

main_menu
