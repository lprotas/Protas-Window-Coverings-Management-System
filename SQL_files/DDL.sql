-- Citations:
    -- Names for data examples taken from The Office TV show
    -- https://canvas.oregonstate.edu/courses/1999601/pages/exploration-mysql-cascade
        -- April 30, 2025
        -- Reference for CASCADE operations
    -- Per TA conversation, the RESET logic should go in your PL.SQL file, since it's a PL/SQL block that wraps your DDL statements. 
----------------------------------------------------------------

-- Disable commits and foreign key checks
SET FOREIGN_KEY_CHECKS=0;
SET AUTOCOMMIT = 0;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Invoices;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

-- Create Customers Table
CREATE TABLE Customers (
    customerID INT AUTO_INCREMENT PRIMARY KEY,
    lastName VARCHAR(145) NOT NULL,
    firstName VARCHAR(145) NOT NULL,
    email VARCHAR(145),
    phone VARCHAR(15) NOT NULL,
    address VARCHAR(145) NOT NULL
);

-- Create Products Table
CREATE TABLE Products (
    productID INT AUTO_INCREMENT PRIMARY KEY,
    productName VARCHAR(145) NOT NULL UNIQUE,
    unitPrice DECIMAL(6,2) NOT NULL
);

-- Create Invoices Table
CREATE TABLE Invoices (
    invoiceID INT AUTO_INCREMENT PRIMARY KEY,
    customerID INT,
    invoiceDate DATE NOT NULL,
    paymentReceived TINYINT(1) DEFAULT 0,
    FOREIGN KEY (customerID) REFERENCES Customers(customerID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Create OrderDetails Table
CREATE TABLE OrderDetails (
    orderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    invoiceID INT,
    productID INT,
    quantity INT NOT NULL,
    FOREIGN KEY (invoiceID) REFERENCES Invoices(invoiceID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (productID) REFERENCES Products(productID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Insert Customers
INSERT INTO Customers (firstName, lastName, email, phone, address) VALUES
('Michael', 'Scott', 'michael.scott@dunderm.com', 5701234567, '1725 Slough Ave, Scranton, PA'),
('Dwight', 'Schrute', 'dwight.schrute@beets.net', 5703456789, '1 Schrute Farms Rd, Honesdale'),
('Jim', 'Halpert', 'jim.halpert@dunderm.com', 5704567890, '88 Prank St, Scranton, PA');

-- Insert Products
INSERT INTO Products (productName, unitPrice) VALUES
('Blinds', 100.00),
('Shades', 150.00),
('Shutters', 200.00);

-- Insert Invoices using subqueries for customerID
INSERT INTO Invoices (customerID, invoiceDate, paymentReceived) VALUES
((SELECT customerID FROM Customers WHERE email = 'michael.scott@dunderm.com'), '2005-03-24', 0),
((SELECT customerID FROM Customers WHERE email = 'dwight.schrute@beets.net'), '2007-05-25', 1),
((SELECT customerID FROM Customers WHERE email = 'dwight.schrute@beets.net'), '2009-07-12', 1);

-- Insert OrderDetails using subqueries for invoiceID and productID
INSERT INTO OrderDetails (invoiceID, productID, quantity) VALUES
(
    (SELECT invoiceID FROM Invoices WHERE invoiceDate = '2005-03-24' AND customerID = (SELECT customerID FROM Customers WHERE email = 'michael.scott@dunderm.com')),
    (SELECT productID FROM Products WHERE productName = 'Blinds'),
    1
),
(
    (SELECT invoiceID FROM Invoices WHERE invoiceDate = '2005-03-24' AND customerID = (SELECT customerID FROM Customers WHERE email = 'michael.scott@dunderm.com')),
    (SELECT productID FROM Products WHERE productName = 'Shades'),
    1
),
(
    (SELECT invoiceID FROM Invoices WHERE invoiceDate = '2007-05-25' AND customerID = (SELECT customerID FROM Customers WHERE email = 'dwight.schrute@beets.net')),
    (SELECT productID FROM Products WHERE productName = 'Shades'),
    2
),
(
    (SELECT invoiceID FROM Invoices WHERE invoiceDate = '2009-07-12' AND customerID = (SELECT customerID FROM Customers WHERE email = 'dwight.schrute@beets.net')),
    (SELECT productID FROM Products WHERE productName = 'Blinds'),
    1
);

-- Enable commits and foreign key checks
SET FOREIGN_KEY_CHECKS=1;
COMMIT;
