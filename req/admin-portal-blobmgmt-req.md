## Add the following screen in the admin portal .

### Side Menu Name: "Blob Storage Management"

### Screen Name: "Blob Storage Management"

The Screen should have 2 tabs:

#### Tab 1: "Blob Storage Management"

The screen should have two sections:

##### Section 1:
In a Horizontal Layout, there should be 3 input fields:
Label: Domain Name
Select: List of Domains (Fetched from the backend)

Label: Container Name
Dropdown: List of Containers (Fetched from the backend)

Button: "Fetch Blobs" (On click, fetch the list of blobs from the backend based on the selected domain and container)

##### Section 2:
A Table to display the list of blobs fetched from the backend. The table should have the following columns:
- Blob Name
- Blob Size
- Last Modified Date
- Actions (View, Download, Delete)

The table should support pagination and sorting.
The Footer of the table should have a button: "Delete Selected" (On click, delete the selected blobs from the backend)
The Footer of the table should have a button: "Clear space" (On click, delete all the  selected blobs from the backend)
The Footer of the table should have a button: "Upload Blob" (On click, open a modal to upload a new blob to the selected container)

#### Tab 2: "Blob Audit Logs"
The screen should have a table to display the audit logs related to blob storage management. The table should have the following columns:
- Log ID
- Action Performed
- User
- Timestamp
- Details (View)

The table should support pagination and sorting.
