## Add the following screen in the admin portal .

### Side Menu Name: "Table Storage Management"

### Screen Name: "Table Storage Management"

The Screen should have 2 tabs:

#### Tab 1: "Table Storage Management"

The screen should have two sections:

##### Section 1:
In a Horizontal Layout, there should be 3 input fields:
Label: Domain Name
Select: List of Domains (Fetched from the backend)

Label: Table Name
Dropdown: List of Tables (Fetched from the backend)

Button: "Fetch Table Details" (On click, fetch the list of tables from the backend based on the selected domain and table)

##### Section 2:
A Table to display the list of data from the azure tables data fetched from the backend. The table should have the following columns:
- Partition Key
- Row Key
- Timestamp
- Key-Value Pairs (View)
- Actions (View, Delete)

The table should support pagination and sorting.
The Footer of the table should have a button: "Delete Selected" (On click, delete the selected tables from the backend)
The Footer of the table should have a button: "Clear space" (On click, delete all the  selected tables from the backend)
The Footer of the table should have a button: "Add New Record" 
    On click, open a modal the modal should have a form to add a new record to the selected table.
    Form Fields:
    - Partition Key (Text Input)
    - Row Key (Text Input)
    - Key-Value Pairs (Dynamic Input Fields to add multiple key-value pairs) 
    - button: "Submit" (On click, submit the form to the backend to add the new record to the selected table)
    - button: "Cancel" (On click, close the modal without adding a new record)


#### Tab 2: "Table Audit Logs"
The screen should have a table to display the audit logs related to table storage management. The table should have the following columns:
- Log ID
- Action Performed
- User
- Timestamp
- Details (View)

The table should support pagination and sorting.
