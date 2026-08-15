## Add the following screen in the admin portal .

### Side Menu Name: "Redis Management"

### Screen Name: "Redis Management"

The Screen should have 2 tabs:

#### Tab 1: "Redis Management"

The screen should have two sections:

##### Section 1:
In a Horizontal Layout, there should be 3 input fields:
Label: Domain Name
Select: List of Domains (Fetched from the backend)

Label: Service Name
Dropdown: List of Services (Fetched from the backend)

Button: "Fetch Redis Keys" (On click, fetch the list of Redis keys from the backend based on the selected domain and service)

##### Section 2:
A Table to display the list of Redis keys fetched from the backend. The table should have the following columns:
- Key Name
- Key Type
- Key Value (as a json string)
- Last Modified Date
- Actions (View, Delete)

The table should support pagination and sorting.
The Footer of the table should have a button: "Delete Selected" (On click, delete the selected Redis keys from the backend)
The Footer of the table should have a button: "Clear All" (On click, delete all the  selected Redis keys from the backend)
The Footer of the table should have a button: "Add New Redis Key" (On click, open a modal to add a new Redis Key and its value to the selected redis region)

#### Tab 2: "Redis Audit Logs"
The screen should have a table to display the audit logs related to Redis management. The table should have the following columns:
- Log ID
- Action Performed
- User
- Timestamp
- Details (View)

The table should support pagination and sorting.
