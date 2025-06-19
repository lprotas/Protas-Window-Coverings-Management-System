----------------------------------------------------------------
-- Lev Protas and Ah Young Lee
-- Group 10
-- CS340 WI25
-- Step 6 (Portfolio Assignment)
-- Citations:
    -- https://canvas.oregonstate.edu/courses/1999601/pages/exploration-implementing-cud-operations-in-your-app?module_item_id=25352968
        -- May 20, 2025
        -- reference for Procedures
----------------------------------------------------------------


-- #############################
-- CREATE Customers
-- #############################
DROP PROCEDURE IF EXISTS sp_CreateCustomer;

DELIMITER //
CREATE PROCEDURE sp_CreateCustomer(
    IN p_firstName VARCHAR(145), 
    IN p_lastName VARCHAR(145), 
    IN p_email VARCHAR(145), 
    IN p_phone VARCHAR(15), 
    IN p_address VARCHAR(145),
    OUT p_customerID INT)
BEGIN
    -- Insert the new customer into the Customers table
    INSERT INTO Customers (firstName, lastName, email, phone, address) 
    VALUES (p_firstName, p_lastName, p_email, p_phone, p_address);

    -- Store the ID of the last inserted row
    SELECT LAST_INSERT_ID() INTO p_customerID;

    -- Display the ID of the newly created customer
    SELECT LAST_INSERT_ID() AS 'new_customer_id';

    -- Example of how to call this procedure:
        -- CALL sp_CreateCustomer('John', 'Doe', 'john.doe@example.com', '555-1234', '123 Main St', @new_customerID);
        -- SELECT @new_customerID AS 'New Customer ID';
END //
DELIMITER ;

-- #############################
-- CREATE Products
-- #############################
DROP PROCEDURE IF EXISTS sp_CreateProduct;

DELIMITER //
CREATE PROCEDURE sp_CreateProduct(
    IN p_productName VARCHAR(145), 
    IN p_unitPrice DECIMAL(6,2), 
    OUT p_productID INT)
BEGIN
    -- Insert the new product into the Products table
    INSERT INTO Products (productName, unitPrice) 
    VALUES (p_productName, p_unitPrice);

    -- Store the ID of the last inserted row
    SELECT LAST_INSERT_ID() INTO p_productID;

    -- Display the ID of the newly created product
    SELECT LAST_INSERT_ID() AS 'new_product_id';

    -- Example of how to call this procedure:
        -- CALL sp_CreateProduct('Curtains', 350.00, @new_productID);
        -- SELECT @new_productID AS 'New Product ID';
END //
DELIMITER ;

-- #############################
-- CREATE Invoices
-- #############################
DROP PROCEDURE IF EXISTS sp_CreateInvoice;

DELIMITER //
CREATE PROCEDURE sp_CreateInvoice(
    IN p_customerID INT(11), 
    IN p_invoiceDate DATE, 
    IN p_paymentReceived TINYINT(1), 
    OUT p_invoiceID INT)
BEGIN
    -- Insert the new invoice into the Invoices table
    INSERT INTO Invoices (customerID, invoiceDate, paymentReceived) 
    VALUES (p_customerID, p_invoiceDate, p_paymentReceived);

    -- Store the ID of the last inserted row
    SELECT LAST_INSERT_ID() INTO p_invoiceID;

    -- Display the ID of the newly created invoice
    SELECT LAST_INSERT_ID() AS 'new_invoice_id';

    -- Example of how to call this procedure:
        -- CALL sp_CreateInvoice(1, "2025-05-30", 1, @new_invoiceID);
        -- SELECT @new_invoiceID AS 'New Invoice ID';
END //
DELIMITER ;

-- #############################
-- UPDATE Invoices
-- #############################
DROP PROCEDURE IF EXISTS sp_UpdateInvoice;

DELIMITER //

CREATE PROCEDURE sp_UpdateInvoicePayment(
    IN p_invoiceID INT,
    IN p_paymentReceived BOOLEAN
)
BEGIN
    UPDATE Invoices
    SET paymentReceived = p_paymentReceived
    WHERE invoiceID = p_invoiceID;
END //
DELIMITER ;


-- #############################
-- CREATE OrderDetails
-- #############################
DROP PROCEDURE IF EXISTS sp_AddOrderDetail;

DELIMITER //
CREATE PROCEDURE sp_AddOrderDetail(
    IN p_invoiceID INT,
    IN p_productID INT,
    IN p_quantity INT,
    OUT p_orderDetailID INT)
BEGIN
    -- Insert the new order detail into the OrderDetails table
    INSERT INTO OrderDetails (invoiceID, productID, quantity)
    VALUES (p_invoiceID, p_productID, p_quantity);

    -- Store the ID of the last inserted row
    SELECT LAST_INSERT_ID() INTO p_orderDetailID;

    -- Display the ID of the newly created order detail
    SELECT LAST_INSERT_ID() AS 'new_orderDetail_id';
END //
DELIMITER ;

-- #############################
-- UPDATE OrderDetails
-- #############################
DROP PROCEDURE IF EXISTS sp_UpdateOrderDetail;

DELIMITER //
CREATE PROCEDURE sp_UpdateOrderDetail(
    IN p_orderDetailID INT,
    IN p_productID INT,
    IN p_quantity INT
)
BEGIN
    -- Update the OrderDetails table with the new productID and quantity
    UPDATE OrderDetails
    SET productID = p_productID,
        quantity = p_quantity
    WHERE orderDetailID = p_orderDetailID;
END //
DELIMITER ;

-- #############################
-- DELETE OrderDetails
-- #############################
DROP PROCEDURE IF EXISTS sp_DeleteOrderDetail;

DELIMITER //
CREATE PROCEDURE sp_DeleteOrderDetail(IN p_orderDetailID INT)
BEGIN
    DECLARE error_message VARCHAR(255);

    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Roll back the transaction on any error
        ROLLBACK;
        -- Propagate the custom error message to the caller
        RESIGNAL;
    END;

    START TRANSACTION;
        -- Delete the order detail from the OrderDetails table
        DELETE FROM OrderDetails WHERE orderDetailID = p_orderDetailID;

        -- Check if the row was deleted
        IF ROW_COUNT() = 0 THEN
            SET error_message = CONCAT('No matching record found in OrderDetails for orderDetailID: ', p_orderDetailID);
            -- Trigger custom error, invoke EXIT HANDLER
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;

    COMMIT;
END //
DELIMITER ;

-- #############################
-- RESET Database
-- #############################
DROP PROCEDURE IF EXISTS sp_reset_db;
DELIMITER //

CREATE PROCEDURE sp_reset_db()
BEGIN

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
END //
DELIMITER ;