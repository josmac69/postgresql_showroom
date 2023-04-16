# Snaphot isolation

PostgreSQL uses snapshot isolation to provide each transaction with a consistent view of the database at the time the transaction started. This ensures that the transaction is not affected by changes made by other concurrent transactions. Here's an overview of how PostgreSQL creates a snapshot for snapshot isolation during a transaction:

1. Assigning a Transaction ID:
When a new transaction starts, PostgreSQL assigns it a unique, monotonically increasing transaction ID (also known as XID). The XID helps PostgreSQL determine the order in which transactions have occurred.

2. Recording Active Transactions:
PostgreSQL maintains a list of active transactions in shared memory. When a new transaction starts, its transaction ID is added to this list. Active transactions are those that have started but not yet committed or rolled back.

3. Creating the Snapshot:
When a transaction begins, PostgreSQL creates a snapshot that includes all rows with an xmin value (the transaction ID that created the row) less than or equal to the current transaction's ID. In other words, the snapshot includes all rows created by transactions that committed before the current transaction started.

Additionally, the snapshot excludes rows with an xmax value (the transaction ID that marked the row as deleted or updated) that belongs to any active transaction. This ensures that the snapshot does not include any uncommitted changes made by concurrent transactions.

4. Visibility Check:
When the transaction reads data from the database, PostgreSQL uses the snapshot to determine the visibility of each row. A row is considered visible to the transaction if:

* The row's xmin is less than or equal to the transaction's ID, meaning it was created by a transaction that committed before the current transaction started.
* The row's xmax is either zero (meaning it hasn't been deleted or updated) or belongs to an active transaction (meaning the deletion or update hasn't been committed yet).
By checking these conditions, PostgreSQL ensures that the transaction only sees the data that was committed before the transaction started, providing a consistent view of the database.

In summary, PostgreSQL creates a snapshot for snapshot isolation during a transaction by assigning a unique transaction ID, maintaining a list of active transactions, and using the transaction ID to determine the visibility of rows based on their xmin and xmax values. This mechanism allows each transaction to work with a consistent view of the database, preventing conflicts and maintaining isolation between concurrent transactions.