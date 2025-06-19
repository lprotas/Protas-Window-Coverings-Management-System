----------------------------------------------------------------
-- Lev Protas and Ah Young Lee
-- Group 10
-- CS340 WI25
-- Step 6 (Portfolio Assignment)

-- Citations:
-- https://www.w3schools.com/sql/sql_update.asp
--     May 7, 2025 — Referenced for UPDATE, DELETE, and INSERT
-- bsg_sample_data_manipulation_queries.sql
--     May 7, 2025 — Reference for correct usage and notation
-- https://www.npmjs.com/package/mysql2
--     May 13, 2025 — Referenced for mysql2 usage and parameterized queries
----------------------------------------------------------------

-- NOTE: Variables are denoted with ? placeholders for mysql2 compatibility

----------------------------------------------------
-- DML statements for the Customers entity
----------------------------------------------------

-- Select all customers
SELECT * FROM Customers;

-- Insert a new customer
INSERT INTO Customers (firstName, lastName, email, phone, address)
VALUES (?, ?, ?, ?, ?);

----------------------------------------------------
-- DML statements for the Products entity
----------------------------------------------------

-- Select all product information
SELECT * FROM Products;

-- Insert a new product
INSERT INTO Products (productName, unitPrice)
VALUES (?, ?);

----------------------------------------------------
-- DML statements for the Invoices entity
----------------------------------------------------

-- Select all invoices with customer info
SELECT Invoices.invoiceID, Customers.firstName, Customers.lastName, 
       Invoices.invoiceDate, Invoices.paymentReceived
FROM Invoices
LEFT JOIN Customers ON Invoices.customerID = Customers.customerID;

-- Select one invoice with customer info
SELECT Invoices.invoiceID, Customers.firstName, Customers.lastName, 
       Invoices.customerID, Invoices.invoiceDate, Invoices.paymentReceived
FROM Invoices
LEFT JOIN Customers ON Invoices.customerID = Customers.customerID
WHERE Invoices.invoiceID = ?;

-- Insert a new invoice
INSERT INTO Invoices (customerID, invoiceDate, paymentReceived)
VALUES (
    (SELECT customerID FROM Customers WHERE firstName = ? AND lastName = ?),
    ?, 
    ?
);

-- Update an invoice
UPDATE Invoices
SET customerID = (SELECT customerID FROM Customers WHERE firstName = ? AND lastName = ?),
    invoiceDate = ?, 
    paymentReceived = ?
WHERE invoiceID = ?;

-- Delete an invoice
DELETE FROM Invoices
WHERE invoiceID = ?;

----------------------------------------------------
-- DML statements for the OrderDetails entity
----------------------------------------------------

-- Select order details with product info
SELECT 
    OrderDetails.orderDetailID, 
    OrderDetails.invoiceID, 
    OrderDetails.productID, 
    Products.productName, 
    Products.unitPrice, 
    OrderDetails.quantity
FROM OrderDetails
LEFT JOIN Products ON OrderDetails.productID = Products.productID;

-- Select product IDs and names for dropdown
SELECT 
    productID, 
    productName 
FROM Products;

-- Select invoice IDs for Add to Existing Invoice form
SELECT 
    invoiceID 
FROM Invoices;

-- Select orderDetailIDs for Edit form dropdown
SELECT 
    orderDetailID 
FROM OrderDetails;

-- Insert new details into an existing invoice
INSERT INTO OrderDetails (invoiceID, productID, quantity)
VALUES (
    ?, 
    (SELECT productID FROM Products WHERE productName = ?), 
    ?
);

-- Select one order detail by orderDetailID for Edit form
SELECT 
    OrderDetails.orderDetailID, 
    OrderDetails.invoiceID, 
    Products.productName, 
    OrderDetails.quantity
FROM OrderDetails
JOIN Products ON OrderDetails.productID = Products.productID
WHERE OrderDetails.orderDetailID = ?;


-- Update an order detail entry
UPDATE OrderDetails
SET 
    productID = (SELECT productID FROM Products WHERE productName = ?),
    quantity = ?
WHERE orderDetailID = ?;

-- Delete an order detail
DELETE FROM OrderDetails
WHERE orderDetailID = ?;
