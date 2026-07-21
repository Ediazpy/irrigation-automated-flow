import getpass

# IrriTrack - Field Service Management App
# Login System

# User storage
# Key: email address
# Value: dictionary with password, role, and name
# Note: Managers can reset passwords if a user forgets theirs
# Note: In production, company's email is used with a generated temp password

users = {
    "admin@thriveoutdoor.com": {
        "password": "temp1234",
        "role": "manager",
        "name": "Admin"
    }
}


# Track failed login attempts
# Key: email
# Value: number of failed attempts
failed_attempts = {}

# Repair items storage
# Key: item name
# Value: dictionary with price, category, and requires_notes (for items needing description)
# Note: Items with price of 0.00 require manual entry by manager

repair_items = {
    # Heads
    "4_inch_head": {"price": 0.00, "category": "heads", "requires_notes": False},
    "6_inch_head": {"price": 0.00, "category": "heads", "requires_notes": False},
    "12_inch_head": {"price": 0.00, "category": "heads", "requires_notes": False},
    "rotor": {"price": 0.00, "category": "heads", "requires_notes": False},
    
    # Stems/Risers
    "4_inch_stem": {"price": 0.00, "category": "stems", "requires_notes": False},
    "6_inch_stem": {"price": 0.00, "category": "stems", "requires_notes": False},
    "12_inch_stem": {"price": 0.00, "category": "stems", "requires_notes": False},
    
    # Nozzles
    "fixed_nozzle": {"price": 0.00, "category": "nozzles", "requires_notes": False},
    "adjustable_nozzle": {"price": 0.00, "category": "nozzles", "requires_notes": False},
    "mp_rotator": {"price": 0.00, "category": "nozzles", "requires_notes": False},
    "rvan_nozzle": {"price": 0.00, "category": "nozzles", "requires_notes": False},
    "bubbler": {"price": 0.00, "category": "nozzles", "requires_notes": False},
    
    # Drip
    "drip_break": {"price": 0.00, "category": "drip", "requires_notes": False},
    "drip_row_per_ft": {"price": 0.00, "category": "drip", "requires_notes": False},
    
    # Pipe - Lateral
    "lateral_under_1ft": {"price": 0.00, "category": "pipe_lateral", "requires_notes": False},
    "lateral_over_1ft": {"price": 0.00, "category": "pipe_lateral", "requires_notes": False},
    
    # Pipe - Mainline
    "mainline_under_1ft": {"price": 0.00, "category": "pipe_mainline", "requires_notes": False},
    "mainline_over_1ft": {"price": 0.00, "category": "pipe_mainline", "requires_notes": False},
    
    # Valves (repair and replace are separate)
    "valve_1_inch_repair": {"price": 0.00, "category": "valves", "requires_notes": False},
    "valve_1_inch_replace": {"price": 0.00, "category": "valves", "requires_notes": False},
    "valve_1.5_inch_repair": {"price": 0.00, "category": "valves", "requires_notes": False},
    "valve_1.5_inch_replace": {"price": 0.00, "category": "valves", "requires_notes": False},
    "valve_2_inch_repair": {"price": 0.00, "category": "valves", "requires_notes": False},
    "valve_2_inch_replace": {"price": 0.00, "category": "valves", "requires_notes": False},
    
    # Controller (manual price entry)
    "controller_replacement": {"price": 0.00, "category": "controller", "requires_notes": True},
    
    # Rain Sensor
    "rain_sensor": {"price": 0.00, "category": "sensor", "requires_notes": False},
    
    # Service Items
    "troubleshoot": {"price": 0.00, "category": "service", "requires_notes": False},
    "locate": {"price": 0.00, "category": "service", "requires_notes": False},
    
    # Wire
    "wire_repair_minimal": {"price": 0.00, "category": "wire", "requires_notes": False},
    "wire_repair_manual": {"price": 0.00, "category": "wire", "requires_notes": True},
    "wire_sprout_replacement": {"price": 0.00, "category": "wire", "requires_notes": False},
    
    # Winterize
    "winterize_system": {"price": 0.00, "category": "winterize", "requires_notes": False},
    
    # Backflow (repair and replace, both need notes)
    "backflow_repair": {"price": 0.00, "category": "backflow", "requires_notes": True},
    "backflow_replacement": {"price": 0.00, "category": "backflow", "requires_notes": True},
    
    # Ball Valve
    "ball_valve_replacement": {"price": 0.00, "category": "ball_valve", "requires_notes": False}
}

# Properties storage
# Key: property_id
# Value: dictionary with address, backflow info, zones, etc.

properties = {}
next_property_id = 1

# Inspections storage
# Key: inspection_id
# Value: dictionary with property_id, technician, date, status, repairs

inspections = {}
next_inspection_id = 1


def add_failed_attempt(email):
     # if email not in container yet, start at 0
    if email not in failed_attempts:
          failed_attempts[email] = 0

    # Add one to their account
    failed_attempts[email] = failed_attempts[email] + 1

    # tell them how many tries left
    remaining = 3 - failed_attempts[email]
    if remaining > 0:
         print(f"Attempts remaining: {remaining}")



def forgot_password():
    print("\nPlease contact your manager to reset your password.")

def handle_failed_login(email):
     # check if account is locked

    if email in failed_attempts:
        if failed_attempts[email]>=3:
            print("Account locked. Please contact your manager to reset.")
            return None

    print("\n1) Try Again")
    print("2) Forgot Password")

    choice = input("Select an option (1-2): ")

    if choice == "1":
         return login() # go back to login screen
    elif choice == "2":
         forgot_password()
         return None
    else:
         print("Invalid option.")
         return handle_failed_login(email)

def login():
    print("=== IrriTrack Login ===")

    email = input("Email: ")

    # check if this email is locked out (3 or more failed attempts)
    if email in failed_attempts:
         if failed_attempts[email] >=3:
              print("Account locked. Please contact your manager to reset.")
              return None
         
    password = getpass.getpass("Password: ")


    # Check if email exists in our users dictionary
    if email in users:
        # Email found, now check if password matches
        if users[email]["password"] == password:
            # Login Successful
            # Login Successful
            failed_attempts[email] = 0 # resets failed attempts
            print(f"Welcome, {users[email]['name']}!")
            user_info = users[email]
            user_info["email"] = email  # Add email to the info we return
            return user_info
        else:
             # Password incorrect
             add_failed_attempt(email)
             return handle_failed_login(email)   
    else:
            # Email not found
            print("Email not found.")
            return handle_failed_login(email)
    


 #=============================== Manager Menu ===================================================================
def manager_menu():
    while True:
        print("\n=== Manager Menu ===")
        print("1) Manage Repair Items")
        print("2) Create Property")
        print("3) View All Properties")
        print("4) Assign Inspections")
        print("5) View Completed Inspections")
        print("6) View Inspection History")
        print("7) Create User")
        print("8) View All Users")
        print("9) Logout")

        choice = input("Select an option (1-9): ")
        
        if choice == "1":
            manager_repair_items()
        elif choice == "2":
            create_property()
        elif choice == "3":
            view_all_properties()
        elif choice == "4":
            assign_inspections()
        elif choice == "5":
            view_completed_inspections()
        elif choice == "6":
            view_inspection_history()
        elif choice == "7":
            create_user()
        elif choice == "8":
            view_all_users()
        elif choice == "9":
            print("Logging out...")
            break
        else:
            print("Invalid option.")

def manager_repair_items():
    while True:
        print("\n=== Manage Repair Items ===")
        print("1) View All Items")
        print("2) Add new Item")
        print("3) Delete Item")
        print("4) Update Price")
        print("5) Back to Main Menu")

        choice = input("Select an option (1-5):")

        if choice == "1":
            view_repair_items()
        elif choice == "2":
            add_repair_item()
        elif choice == "3":
            delete_repair_item()
        elif choice == "4":
            update_repair_price()
        elif choice == "5":
            break
        else:
            print("Invalid option.")

#=============== View Repair Items ==========================================
def view_repair_items():
    print("\n=== All Repair Items ===")
    
    for item_name in repair_items:
        item = repair_items[item_name]
        price = item["price"]
        category = item["category"]
        print(f"  {item_name}: ${price:.2f} ({category})")

def add_repair_item():
    print("\n=== Add New Repair Item ===")

    #Get item name
    item_name = input("Item name (use underscores, e.g. 'new_sprinkler'):")

    # Check if item already exists
    if item_name in repair_items:
        print(f"Item '{item_name}' already exists.")
        return
    
    # Get price 
    price_input = input("Price: $")
    price = float(price_input) # Convert text to number

     # Get category
    print("\nCategories: heads, stems, nozzles, drip, pipe_lateral, pipe_mainline,")
    print("            valves, controller, sensor, service, wire, winterize,")
    print("            backflow, ball_valve")
    category = input("Category: ")
    
    # Requires notes?
    notes_input = input("Requires notes? (y/n): ")
    requires_notes = notes_input.lower() == "y"  # True if they typed 'y'
    
    # Add to dictionary
    repair_items[item_name] = {
        "price": price,
        "category": category,
        "requires_notes": requires_notes
    }
    
    print(f"\nItem '{item_name}' added successfully!")

def delete_repair_item():
    print("\n=== Delete Repair Item ===")
    
    # show current items so manager knows what's available
    print("Current Items:")
    for item_name in repair_items:
        print(f"  - {item_name}")

    # Get item name to delete
    item_name = input("\nenter item name to delete (or 'cancel' to go back): ")

    # Check if they want to cancel
    if item_name.lower() == "cancel":
        return
    
    # Check if item exists
    if item_name in repair_items:
        # Confirm before deleting
        confirm = input(f" Are you sure you want to delete '{item_name}'? (y/n): ")

        if confirm.lower() == "y":
            del repair_items[item_name] # Remove from dictionary
            print(f"Item '{item_name}' deleted.")

        else:
            print("Delete cancelled.")
    else:
        print(f"Item '{item_name}' not found.")

def update_repair_price():
    print("\n=== Update Repair Price ===")

    # Show current items with prices
    print("Current items:")
    for item_name in repair_items:
        item = repair_items[item_name]
        print(f"  - {item_name}: ${item['price']:.2f}")


    # Get item name to update
    item_name = input("\nEnter item name to update (or 'cancel' to go back): ")

    # Check if they want to cancel
    if item_name.lower() == "cancel":
        return
    
    #Check if item exists
    if item_name in repair_items:
        # Show current price
        current_price = repair_items[item_name]["price"]
        print(f"Current price: ${current_price:.2f}")

        # Get new price
        new_price_input = input("New price: $")
        new_price = float(new_price_input)

        # Update the price
        repair_items[item_name]["price"] = new_price

        print(f"Price updated: {item_name} is now ${new_price:.2f}")
    else:
        print(f"Item '{item_name}' not found.")


#===================View Repair Items END ===========================================
def assign_inspections():
    global next_inspection_id
    
    print("\n=== Assign Inspection ===")
    
    # Check if we have properties
    if len(properties) == 0:
        print("No properties found. Create a property first.")
        input("Press Enter to continue...")
        return
    
    # Show list of properties
    print("\n-- Select Property --")
    for prop_id in properties:
        prop = properties[prop_id]
        print(f"  {prop_id}) {prop['address']}")
    
    prop_choice = input("Enter property ID: ")
    prop_choice = int(prop_choice)
    
    # Check if property exists
    if prop_choice not in properties:
        print("Property not found.")
        return
    
    # Get list of technicians only
    print("\n-- Select Technician --")
    technicians = []  # Empty list to store technician emails
    
    for email in users:
        user = users[email]
        if user["role"] == "technician":
            technicians.append(email)
            print(f"  {len(technicians)}) {user['name']} - {email}")
    
    # Check if we have any technicians
    if len(technicians) == 0:
        print("No technicians found. Create a technician first.")
        return
    
    tech_choice = input("Enter technician number: ")
    tech_choice = int(tech_choice)
    
    # Check if valid choice
    if tech_choice < 1 or tech_choice > len(technicians):
        print("Invalid selection.")
        return
    
    # Get the technician email (list starts at 0, but we showed starting at 1)
    tech_email = technicians[tech_choice - 1]
    
    # Get date for inspection
    inspection_date = input("Inspection date (e.g., 2025-01-15): ")
    
    # Create the inspection
    inspections[next_inspection_id] = {
        "property_id": prop_choice,
        "technician": tech_email,
        "date": inspection_date,
        "status": "assigned",
        "repairs": [],
        "total_cost": 0.00
    }
    
    # Get property and tech info for confirmation
    prop = properties[prop_choice]
    tech = users[tech_email]
    
    print(f"\nInspection assigned successfully!")
    print(f"  ID: {next_inspection_id}")
    print(f"  Property: {prop['address']}")
    print(f"  Technician: {tech['name']}")
    print(f"  Date: {inspection_date}")
    print(f"  Status: assigned")
    
    next_inspection_id = next_inspection_id + 1


def view_completed_inspections():
    print("\n=== Completed Inspections (Ready for Billing) ===")

    # 1. Quick check if database is empty
    if len(inspections) == 0:
        print("No inspections in the system.")
        input("Press Enter to continue...")
        return

    # 2. Print a clean table header
    # The :< numbers force the columns to line up nicely
    print(f"{'ID':<4} | {'Date':<11} | {'Technician':<15} | {'Property':<20} | {'Total':<10}")
    print("-" * 75)

    found_any = False

    # 3. Loop through database
    for insp_id in inspections:
        insp = inspections[insp_id]

        # 4. FILTER: We ONLY want status "completed"
        if insp["status"] == "completed":
            found_any = True

            # Get the linked data (Property Address and Tech Name)
            prop = properties[insp["property_id"]]
            tech_name = users[insp["technician"]]["name"]

            # Truncate address if it's too long so it fits in the table
            addr = prop['address']
            if len(addr) > 18:
                addr = addr[:18] + ".."

            # Print the row
            print(f"{insp_id:<4} | {insp['date']:<11} | {tech_name:<15} | {addr:<20} | ${insp['total_cost']:<10.2f}")

    # 5. If we loop through everything and find nothing
    if not found_any:
        print("(No completed inspections found yet)")

    print("-" * 75)
    input("Press Enter to return to menu...")


def view_inspection_history():
    print("\n=== Inspection History (Archive) ===")

    if len(inspections) == 0:
        print("No inspections found in database.")
        input("Press Enter...")
        return

    print(f"{'ID':<5} | {'Date':<12} | {'Technician':<20} | {'Status':<12} | {'Total':<10}")
    print("-" * 70)

    found_any = False
    for insp_id in inspections:
        insp = inspections[insp_id]

        # We show ALL inspections here (Active AND Completed)
        # This acts as your master database view
        tech_name = users[insp["technician"]]["name"]

        # Simple formatting to make it look like a table
        print(
            f"{insp_id:<5} | {insp['date']:<12} | {tech_name:<20} | {insp['status']:<12} | ${insp['total_cost']:<10.2f}")
        found_any = True

    if not found_any:
        print("(No history found)")

    print("-" * 70)
    input("Press Enter to return to menu...")

def create_user():
    print("\n=== Create New User ===")
    
    # Get user's name
    name = input("Enter name: ")
    
    # Get user's email
    email = input("Enter email: ")
    
    # Check if email already exists
    if email in users:
        print(f"User with email '{email}' already exists.")
        return
    
    # Choose role
    print("\nRole:")
    print("1) Technician")
    print("2) Manager")
    role_choice = input("Select role (1-2): ")
    
    if role_choice == "1":
        role = "technician"
    elif role_choice == "2":
        role = "manager"
    else:
        print("Invalid role. User not created.")
        return
    
    # Create temporary password
    temp_password = "temp1234"
    
    # Add to users dictionary
    users[email] = {
        "password": temp_password,
        "role": role,
        "name": name
    }
    
    print(f"\nUser created successfully!")
    print(f"  Name: {name}")
    print(f"  Email: {email}")
    print(f"  Role: {role}")
    print(f"  Temporary Password: {temp_password}")
    print("\nPlease have the user change their password after first login.")
def view_all_users():
    print("\n=== All Users ===")
    
    for email in users:
        user = users[email]
        name = user["name"]
        role = user["role"]
        print(f"  {name} ({role}) - {email}")

def create_property():
    global next_property_id  # We need this to update the ID counter
    
    print("\n=== Create New Property ===")
    
    # Basic info
    address = input("Property address: ")
    meter_location = input("Meter location: ")
    
    # Backflow info
    print("\n-- Backflow Info --")
    backflow_location = input("Backflow location: ")
    backflow_size = input("Backflow size (e.g., 1, 1.5, 2): ")
    backflow_serial = input("Backflow serial #: ")
    
    # Controller info
    print("\n-- Controller Info --")
    num_controllers = input("Number of controllers: ")
    num_controllers = int(num_controllers)  # Convert to number
    controller_location = input("Controller location: ")
    
    # Zones
    print("\n-- Zones --")
    num_zones = input("How many zones? ")
    num_zones = int(num_zones)  # Convert to number
    
    zones = []  # Empty list to store zone info
    
    for i in range(1, num_zones + 1):
        print(f"\n  Zone {i}:")
        description = input("    Description (e.g., front of building): ")
        
        print("    Head type options: spray, rotor, mp_rotator, drip, bubbler, mixed")
        head_type = input("    Head type: ")
        
        head_count_input = input("    Head count (or Enter to skip): ")
        if head_count_input == "":
            head_count = 0
        else:
            head_count = int(head_count_input)
        
        # Add this zone to our list
        zone = {
            "zone_number": i,
            "description": description,
            "head_type": head_type,
            "head_count": head_count
        }
        zones.append(zone)
    
    # Create the property
    properties[next_property_id] = {
        "address": address,
        "meter_location": meter_location,
        "backflow_location": backflow_location,
        "backflow_size": backflow_size,
        "backflow_serial": backflow_serial,
        "num_controllers": num_controllers,
        "controller_location": controller_location,
        "zones": zones
    }
    
    print(f"\nProperty created successfully! (ID: {next_property_id})")
    next_property_id = next_property_id + 1  # Increase for next property

def view_all_properties():
    print("\n=== All Properties ===")
    
    if len(properties) == 0:
        print("No properties found.")
        return
    
    for prop_id in properties:
        prop = properties[prop_id]
        print(f"\n  ID: {prop_id}")
        print(f"  Address: {prop['address']}")
        print(f"  Meter: {prop['meter_location']}")
        print(f"  Backflow: {prop['backflow_size']}\" at {prop['backflow_location']}")
        print(f"  Controllers: {prop['num_controllers']} at {prop['controller_location']}")
        print(f"  Zones: {len(prop['zones'])}")
        
        for zone in prop['zones']:
            print(f"    Zone {zone['zone_number']}: {zone['description']} - {zone['head_type']} x{zone['head_count']}")

#============================== Manager Menu END ===================================================================

#============================== Tech Menu ==========================================================================
def tech_menu(logged_in_user):
    while True:
        print("\n=== Technician Menu ===")
        print("1) My Assigned Inspections")
        print("2) Start/Continue Inspection (Assigned)")
        print("3) Start New Inspection (Create Property)")  # <--- NEW
        print("4) View Completed Inspections")
        print("5) Logout")

        choice = input("Select an option (1-5): ")

        if choice == "1":
            view_my_inspections(logged_in_user)
        elif choice == "2":
            start_inspection(logged_in_user)
        elif choice == "3":
            tech_create_walk(logged_in_user)  # <--- NEW FUNCTION
        elif choice == "4":
            view_my_completed(logged_in_user)
        elif choice == "5":
            print("Logging out...")
            break
        else:
            print("Invalid option.")

def view_my_inspections(logged_in_user):
    print("\n=== My Assigned Inspections ===")
    
    my_email = logged_in_user["email"]
    found = False
    
    for insp_id in inspections:
        insp = inspections[insp_id]
        
        # Only show inspections assigned to me
        if insp["technician"] == my_email:
            # Only show assigned or in_progress (not completed)
            if insp["status"] in ["assigned", "in_progress"]:
                found = True
                prop = properties[insp["property_id"]]
                print(f"\n  Inspection #{insp_id}")
                print(f"    Property: {prop['address']}")
                print(f"    Date: {insp['date']}")
                print(f"    Status: {insp['status']}")
    
    if not found:
        print("No assigned inspections.")
    
    input("\nPress Enter to continue...")

def start_inspection(logged_in_user):
    print("\n=== Start/Continue Inspection ===") 
    my_email = logged_in_user["email"]

    #Find my assigned or in progress inspections
    my_inspections = []

    for insp_id in inspections:
        insp = inspections[insp_id]
        if insp["technician"] ==  my_email:
            if insp["status"] in ["assigned", "in_progress"]:
                my_inspections.append(insp_id)
    # Check if we have any
    if len(my_inspections) == 0:
        print("No inspections to work on.")
        input("Press Enter to continue...")
        return
    
    # Show List of inspections
    print("\nSelect an inspection:")
    for i, insp_id in enumerate(my_inspections, 1):
        insp = inspections[insp_id]
        prop = properties[insp["property_id"]]
        print(f"  {i}) {prop['address']} - {insp['date']} ({insp['status']})")

    choice = input("Enter number: ")
    choice = int(choice)

    #validation
    if choice < 1 or choice > len(my_inspections):
        print("Invalid selection.")
        return

    # Get the actual ID
    selected_id = my_inspections[choice - 1]
    #update status to in_progress so manager sees we started
    inspections[selected_id]["status"] = "in_progress"

    # Start the actual work flow

    do_inspection(selected_id)
        
    
def do_inspection(inspection_id):
    # Load the data we need
    insp = inspections[inspection_id]
    prop = properties[insp["property_id"]]

    while True:
        print(f"\n=== Inspection: {prop['address']} ===")
        print(f"Date: {insp['date']}")
        print(f"Status: {insp['status']}")
        # Show how many repairs we have logged so far
        print(f"Repairs logged: {len(insp['repairs'])}")

        print("\n1) Walk Zones (add repairs)")
        print("2) View Current Repairs")
        print("3) Submit Inspection")
        print("4) Save and Exit")

        choice = input("Select an option (1-4): ")

        if choice == "1":
            walk_zones(inspection_id)
        elif choice == "2":
            pass  # We will build this later
        elif choice == "3":
            submit_inspection(inspection_id)
            break
        elif choice == "4":
            print("Progress saved.")
            break
        else:
            print("Invalid option.")
# MENU OPTION 1
def walk_zones(inspection_id):

    # load the data we need
    insp = inspections[inspection_id]
    prop = properties[insp["property_id"]]

    print(f"\n=== Walking Zones at {prop['address']} ===")

    # Loop through each zone in the property list
    for zone in prop["zones"]:

        # Create loop specifically for this zone
        while True:
            print(f"\n--- Zone {zone['zone_number']} ---")
            print(f"Description: {zone['description']}")
            print(f"Heads: {zone['head_type']} (x{zone['head_count']})")

            # 4. Show repairs already logged for THIS zone
            print("Repairs logged here:")
            found_repair = False
            for r in insp["repairs"]:
                if r["zone_number"] == zone["zone_number"]:
                    print(f"  - {r['item_name']} (x{r['quantity']})")
                    found_repair = True

            if not found_repair:
                print("  (None)")

            # 5. Ask what to do
            print("\n1) Add Repair to this Zone")
            print("2) Next Zone")

            choice = input("Select (1-2): ")

            if choice == "1":
                add_repair(inspection_id, zone["zone_number"])
            elif choice == "2":
                break  # Breaks the 'while' loop, moves to the next 'for' loop item
            else:
                print("Invalid option.")

    print("\nAll zones walked! Returning to menu.")
    input("Press Enter...")

# MENU OPTION 3

def submit_inspection(inspection_id):
    print("\n=== Submitting Inspection ====")

    insp = inspections[inspection_id]

    # check if there are any repairs to total up

    total_cost = 0

    if len(insp["repairs"]) > 0:
        print("Calculating totals....")
        for r in insp["repairs"]:
            item_total = r["quantity"] * r["price"]
            total_cost += item_total
            #print(f"  + {r['item_name']}: ${item_total:.2f}")

    # save total cost to the inspection
    insp["total_cost"] = total_cost

    # this updates the status
    insp["status"] = "completed"

    print("-" * 30)
    #print(f"Total Invoice: ${total_cost:.2f}")
    print("Status updated to: COMPLETED")
    print("This inspection is now locked and archived.")
    input("Press Enter to finish...")






def add_repair(inspection_id, zone_number):
    print(f"\n--- Add Repair to zone {zone_number} ---")

    # Get all unique categories from our repair list
    categories = []
    for item in repair_items:
        cat = repair_items[item]["category"]
        if cat not in categories:
            categories.append(cat)

    # show categories to the user
    print("Select Category:")
    for i, cat in enumerate(categories, 1):
        print(f"  {i} {cat}")

    # get category choice
    cat_choice = input("Enter number: ")
    try:
        cat_index = int(cat_choice) - 1
        selected_cat = categories[cat_index]
    except:
        print("Invalid Selection")
        return

    # find all items in that category
    category_items = []
    for item_name in repair_items:
        if repair_items[item_name]["category"] == selected_cat:
            category_items.append(item_name)

    # show items in that category
    print(f"\n--- {selected_cat} ---")
    for i, item_name in enumerate(category_items, 1):
        price = repair_items[item_name]["price"]
        print(f"  {i}) {item_name}")

    #  Get item choice
    item_choice = input("Select item number: ")
    try:
        item_index = int(item_choice) - 1
        selected_item_name = category_items[item_index]
    except:
        print("Invalid item.")
        return

    #  Get Quantity
    qty = input("Quantity: ")
    try:
        qty = int(qty)
    except:
        qty = 1  # Default to 1 if they type nonsense

    # Check if notes are required
    notes = ""
    item_data = repair_items[selected_item_name]
    if item_data["requires_notes"]:
        notes = input("Enter description/notes: ")

    # Save the repair!
    new_repair = {
        "zone_number": zone_number,
        "item_name": selected_item_name,
        "quantity": qty,
        "price": item_data["price"],
        "notes": notes
    }

    # Add to the inspection's repair list
    inspections[inspection_id]["repairs"].append(new_repair)
    print("Repair added!")


def view_my_completed(logged_in_user):
    print("\n=== My Completed Inspections ===")

    # 1. Get my email
    my_email = logged_in_user["email"]
    found = False

    # 2. Loop through all inspections
    for insp_id in inspections:
        insp = inspections[insp_id]

        # 3. Check TWO things:
        #    Is it mine? AND Is it done?
        if insp["technician"] == my_email and insp["status"] == "completed":
            found = True
            prop = properties[insp["property_id"]]

            # 4. Print the summary
            print(f"\n  Inspection #{insp_id}")
            print(f"    Property: {prop['address']}")
            print(f"    Date:     {insp['date']}")
            print(f"    Repairs:  {len(insp['repairs'])} items")
            # We show the total cost here (we will calculate this in the next step)
            print(f"    Total:    ${insp['total_cost']:.2f}")
            print("-" * 30)

    if not found:
        print("No completed inspections found.")

    input("\nPress Enter to continue...")


def tech_create_walk(logged_in_user):
    global next_property_id
    global next_inspection_id

    print("\n=== Start New Inspection (New Property) ===")

    # --- PART 1: COLLECT PROPERTY DATA ---
    address = input("Property address: ")
    meter_location = input("Meter location: ")

    print("\n-- Backflow Info --")
    backflow_location = input("Backflow location: ")
    backflow_size = input("Backflow size (e.g., 1, 1.5, 2): ")
    backflow_serial = input("Backflow serial #: ")

    print("\n-- Controller Info --")
    try:
        num_controllers = int(input("Number of controllers: "))
    except:
        num_controllers = 1  # Default if they type nonsense

    controller_location = input("Controller location: ")

    # --- PART 2: ZONES ---
    print("\n-- Zones --")
    try:
        num_zones = int(input("How many zones? "))
    except:
        num_zones = 0

    zones = []
    for i in range(1, num_zones + 1):
        print(f"\n  Zone {i}:")
        description = input("    Description: ")
        head_type = input("    Head type: ")

        try:
            head_count = int(input("    Head count (Enter to skip): ") or 0)
        except:
            head_count = 0

        zones.append({
            "zone_number": i,
            "description": description,
            "head_type": head_type,
            "head_count": head_count
        })

    # --- PART 3: SAVE PROPERTY ---
    # We use the current next_property_id
    new_prop_id = next_property_id

    properties[new_prop_id] = {
        "address": address,
        "meter_location": meter_location,
        "backflow_location": backflow_location,
        "backflow_size": backflow_size,
        "backflow_serial": backflow_serial,
        "num_controllers": num_controllers,
        "controller_location": controller_location,
        "zones": zones
    }

    # Increment the counter so the next property gets a new ID
    next_property_id = next_property_id + 1

    # --- PART 4: CREATE INSPECTION ---
    # We auto-assign this to the technician whois logged in
    inspection_date = input("\nInspection Date (e.g. 2025-01-01): ")

    new_insp_id = next_inspection_id

    inspections[new_insp_id] = {
        "property_id": new_prop_id,
        "technician": logged_in_user["email"],  # Assign to ME
        "date": inspection_date,
        "status": "in_progress",  # Already started
        "repairs": [],
        "total_cost": 0.00
    }

    next_inspection_id = next_inspection_id + 1

    print(f"\nProperty and Inspection created!")
    input("Press Enter to start walking zones...")

    # --- PART 5: JUMP STRAIGHT TO WORK ---
    do_inspection(new_insp_id)

#=================== Tech Menu END ==============================================================

while True:
    logged_in_user = login()

    if logged_in_user is not None:
        if logged_in_user["role"] == "manager":
            manager_menu()
        
        else:
            tech_menu(logged_in_user)
    
    # After logout, ask if they want to login again or exit
    again = input("\nLogin again? (y/n): ")
    if again.lower() != "y":
        print("Goodbye!")
        break
