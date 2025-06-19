////////////////////////////////////////////////////////////////////////////////
// Citations:
// https://canvas.oregonstate.edu/courses/1999601/pages/exploration-implementing-cud-operations-in-your-app?module_item_id=25352968
// for CRUD operations
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// SETUP
// Includes setting up express, the port, database, and handlebars
////////////////////////////////////////////////////////////////////////////////

const express = require('express');
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

const PORT = 1652;

// Database
const db = require('./database/db-connector');

// Handlebars
const { engine } = require('express-handlebars');
app.engine('.hbs', engine({
    extname: '.hbs',
}));
app.set('view engine', '.hbs');

////////////////////////////////////////////////////////////////////////////////
// ROUTE HANDLERS
// Includes route handlers for the home page, reset, customers, products, invoices, and invoice details
////////////////////////////////////////////////////////////////////////////////

// Home page route
app.get('/', async function (req, res) {
    try {
        res.render('home');
    } catch (error) {
        console.error('Error rendering page:', error);
        res.status(500).send('An error occurred while rendering the page.');
    }
});

// Reset route
app.post('/reset', async function (req, res) {
    try {
        // Create and execute our queries
        // Using parameterized queries (Prevents SQL injection attacks)
        const query1 = `CALL sp_reset_db;`;
        await db.query(query1);

        console.log(`site reset.`);

        // Redirect the user to the updated webpage
        res.redirect('/');
    } catch (error) {
        console.error('Error executing queries:', error);
        // Send a generic error message to the browser
        res.status(500).send(
            'An error occurred while executing the database queries.'
        );
    }
});

////////////////////////////////////////////////////////////////////////////////
// CUSTOMERS ROUTES
// Includes route handlers for the customers page, and adding a customer
////////////////////////////////////////////////////////////////////////////////

// Customers page route
app.get('/customers', async function (req, res) {
    try {
        const query = `SELECT * FROM Customers;`;
        const [customers] = await db.query(query);
        res.render('customers', { customers: customers });
    } catch (error) {
        console.error('Error fetching customers:', error);
        res.status(500).send('An error occurred while retrieving customers.');
    }
});

// CREATE ROUTE for Customers
app.post('/customers/add', async function (req, res) {
    try {
        // Parse frontend form information
        let data = req.body;

        // Create and execute the query using the stored procedure
        const query = `CALL sp_CreateCustomer(?, ?, ?, ?, ?, @new_customerID);`;

        // Execute the query
        const [[[rows]]] = await db.query(query, [
            data.create_customer_firstName,
            data.create_customer_lastName,
            data.create_customer_email,
            data.create_customer_phone,
            data.create_customer_address,
        ]);

        console.log(`New Customer ID: ${rows.new_customer_id} ` +
            `Name: ${data.create_customer_firstName} ${data.create_customer_lastName}`);

        // Redirect the user to the customer page
        res.redirect(`/customers`);
    } catch (error) {
        console.error('Error adding customer:', error);
        // Send a generic error message to the browser
        res.status(500).send('An error occurred while adding the customer.');
    }
});

////////////////////////////////////////////////////////////////////////////////
// PRODUCTS ROUTES
// Includes route handlers for the products page, adding a product, and deleting a product
////////////////////////////////////////////////////////////////////////////////

// Products page route
app.get('/products', async function (req, res) {
    try {
        const query1 = 'SELECT * FROM Products;';
        const [prods] = await db.query(query1);
        res.render('products', { prods: prods });
    } catch (error) {
        console.error('Error executing queries:', error);
        res.status(500).send('An error occurred while executing the database queries.');
    }
});

// CREATE ROUTE for Products
app.post('/products/add', async function (req, res) {
    try {
        // Parse frontend form information
        let data = req.body;

        // Create and execute the query using the stored procedure
        const query = `CALL sp_CreateProduct(?, ?, @new_productID);`;

        // Execute the query
        const [[[rows]]] = await db.query(query, [
            data.create_product_name,
            data.create_product_price,
        ]);

        console.log(`New Product ID: ${rows.new_product_id} ` +
            `Name: ${data.create_product_name}`);

        // Redirect the user to the product page
        res.redirect(`/products`);
    } catch (error) {
        console.error('Error adding product:', error);
        // Send a generic error message to the browser
        res.status(500).send('An error occurred while adding the product.');
    }
});

// Remove this route if it exists
app.post('/products/delete', async function (req, res) {
    const { delete_prod_id } = req.body;

    const deleteQuery = `
        DELETE FROM Products
        WHERE productID = ?;
    `;

    try {
        await db.query(deleteQuery, [delete_prod_id]);
        res.redirect('/products');
    } catch (error) {
        console.error('Error deleting product:', error);
        res.status(500).send('An error occurred while deleting the product.');
    }
});

////////////////////////////////////////////////////////////////////////////////
// INVOICES ROUTES
// Includes route handlers for the invoices page, adding an invoice, and updating an invoice
////////////////////////////////////////////////////////////////////////////////

// Invoices page route
app.get('/invoices', async function (req, res) {
    try {
        const query1 = `
            SELECT Invoices.invoiceID, Customers.firstName, Customers.lastName, 
                   Invoices.invoiceDate, Invoices.paymentReceived, Invoices.customerID
            FROM Invoices
            LEFT JOIN Customers ON Invoices.customerID = Customers.customerID;
        `;
        const query2 = `SELECT * FROM Customers;`;

        const [orders] = await db.query(query1);

        // Format the date
        orders.forEach(order => {
            if (order.invoiceDate instanceof Date) {
                const month = String(order.invoiceDate.getMonth() + 1).padStart(2, '0');
                const day = String(order.invoiceDate.getDate()).padStart(2, '0');
                const year = order.invoiceDate.getFullYear();
                order.invoiceDate = `${month}-${day}-${year}`;
            }
        });

        const [customers] = await db.query(query2);

        res.render('invoices', {
            orders: orders || [],
            customers: customers || []
        });
    } catch (error) {
        console.error('Error fetching invoices:', error);
        res.status(500).send('An error occurred while fetching invoices.');
    }
});

// Add invoice route
app.post('/invoices/add', async function (req, res) {
    try {
        const {
            create_invoice_customer,
            create_invoice_date,
            create_invoice_payment
        } = req.body;

        const paymentReceived = create_invoice_payment ? 1 : 0;

        const query = `CALL sp_CreateInvoice(?, ?, ?, @new_invoiceID);`;
        const params = [
            create_invoice_customer,
            create_invoice_date,
            paymentReceived
        ];

        await db.query(query, params);
        console.log('New invoice added.');
        res.redirect('/invoices');
    } catch (error) {
        console.error('Error adding invoice:', error);
        res.status(500).send('An error occurred while adding the invoice.');
    }
});

// Update invoice route
app.post('/invoices/update', async function (req, res) {
    const { invoiceID, paymentReceived } = req.body;

    // Convert paymentReceived to 0 or 1
    const paymentBool = Number(paymentReceived) === 1 ? 1 : 0;

    // Update only the paymentReceived field
    const query = `CALL sp_UpdateInvoicePayment(?, ?);`; // Use a new stored procedure
    const params = [invoiceID, paymentBool];

    try {
        await db.query(query, params);
        console.log(`Updated invoice ${invoiceID}: paymentReceived = ${paymentBool}`);
        res.redirect('/invoices');
    } catch (error) {
        console.error('Error updating invoice payment:', error);
        res.status(500).send('An error occurred while updating the invoice payment.');
    }
});

////////////////////////////////////////////////////////////////////////////////
// INVOICE DETAILS ROUTES
// Includes route handlers for fetching invoice details, adding an order detail, updating an order detail, and deleting an order detail
////////////////////////////////////////////////////////////////////////////////

// Fetch invoice details route
app.get('/invoices/:id', async function (req, res) {
    const invoiceID = req.params.id;

    const invoiceQuery = `
        SELECT Invoices.invoiceID, Customers.firstName, Customers.lastName, 
               Invoices.customerID, Invoices.invoiceDate, Invoices.paymentReceived
        FROM Invoices
        LEFT JOIN Customers ON Invoices.customerID = Customers.customerID
        WHERE Invoices.invoiceID = ?;
    `;

    const detailsQuery = `
        SELECT OrderDetails.orderDetailID, OrderDetails.invoiceID, OrderDetails.productID,
               COALESCE(Products.productName, '[Deleted Product]') AS productName,
               COALESCE(Products.unitPrice, 0) AS unitPrice,
               OrderDetails.quantity
        FROM OrderDetails
        LEFT JOIN Products ON OrderDetails.productID = Products.productID
        WHERE OrderDetails.invoiceID = ?;
    `;

    const customersQuery = `SELECT * FROM Customers;`;
    const productsQuery = `SELECT productID, productName FROM Products;`;

    try {
        const [[invoice]] = await db.query(invoiceQuery, [invoiceID]);
        const [details] = await db.query(detailsQuery, [invoiceID]);
        const [rawCustomers] = await db.query(customersQuery);
        const [products] = await db.query(productsQuery);

        // Add isSelected flag to each customer object
        const customers = rawCustomers.map(c => ({
            ...c,
            isSelected: c.customerID === invoice.customerID
        }));

        if (!invoice) {
            return res.status(404).send('Invoice not found.');
        }

        res.render('invoice-details', { invoice, details: details || [], customers, products });
    } catch (error) {
        console.error('Error fetching invoice details:', error);
        res.status(500).send('An error occurred while retrieving the invoice.');
    }
});

// Add order detail route
app.post('/invoices/:id/add-order', async function (req, res) {
    try {
        // Parse frontend form information
        const invoiceID = req.params.id; // Get the invoice ID from the URL
        const { productID, quantity } = req.body; // Get productID and quantity from the form

        // Create and execute the query using the stored procedure
        const query = `CALL sp_AddOrderDetail(?, ?, ?, @new_orderDetailID);`;

        // Execute the query
        const [[[rows]]] = await db.query(query, [invoiceID, productID, quantity]);

        console.log(`Added order detail to Invoice ID: ${invoiceID}, Product ID: ${productID}, Quantity: ${quantity}`);
        console.log(`New Order Detail ID: ${rows.new_orderDetail_id}`);

        // Redirect the user to the invoice details page
        res.redirect(`/invoices/${invoiceID}`);
    } catch (error) {
        console.error('Error adding order detail:', error);
        // Send a generic error message to the browser
        res.status(500).send('An error occurred while adding the order detail.');
    }
});

// Update order detail route
app.post('/invoices/:id/update-order', async function (req, res) {
    try {
        // Parse frontend form information
        const invoiceID = req.params.id; // Get the invoice ID from the URL
        const { orderDetailID, productID, quantity } = req.body; // Get order detail data from the form

        // Create and execute the query using the stored procedure
        const query1 = `CALL sp_UpdateOrderDetail(?, ?, ?);`;
        const query2 = `SELECT productName FROM Products WHERE productID = ?;`;

        // Execute the update query
        await db.query(query1, [orderDetailID, productID, quantity]);

        // Fetch the updated product name for logging
        const [[rows]] = await db.query(query2, [productID]);

        console.log(`UPDATE OrderDetails. OrderDetail ID: ${orderDetailID}, ` +
            `Product: ${rows.productName}, Quantity: ${quantity}`
        );

        // Redirect the user to the invoice details page
        res.redirect(`/invoices/${invoiceID}`);
    } catch (error) {
        console.error('Error updating order detail:', error);
        // Send a generic error message to the browser
        res.status(500).send('An error occurred while updating the order detail.');
    }
});

// Delete order detail route
app.post('/invoices/:id/delete-order', async function (req, res) {
    try {
        // Parse frontend form information
        const invoiceID = req.params.id; // Get the invoice ID from the URL
        const { orderDetailID } = req.body; // Get the orderDetailID from the form

        // Create and execute the query using the stored procedure
        const query = `CALL sp_DeleteOrderDetail(?);`;

        // Execute the delete query
        await db.query(query, [orderDetailID]);

        console.log(`DELETE OrderDetails. OrderDetail ID: ${orderDetailID}`);

        // Redirect the user to the invoice details page
        res.redirect(`/invoices/${invoiceID}`);
    } catch (error) {
        console.error('Error deleting order detail:', error);
        // Send a generic error message to the browser
        res.status(500).send('An error occurred while deleting the order detail.');
    }
});

////////////////////////////////////////////////////////////////////////////////
// LISTENER
// Starts the express server
////////////////////////////////////////////////////////////////////////////////

app.listen(PORT, function () {
    console.log('Express started on http://localhost:' + PORT + '; press Ctrl-C to terminate.');
});