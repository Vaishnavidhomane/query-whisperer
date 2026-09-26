-- ============================================================
-- NL2SQL Analytics Engine — Schema & Sample Data
-- Domain: E-commerce order analytics
-- ============================================================

DROP DATABASE IF EXISTS nl2sql_demo;
CREATE DATABASE nl2sql_demo;
USE nl2sql_demo;

-- ---------- Tables ----------

CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id  INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(100) NOT NULL UNIQUE,
    city         VARCHAR(50),
    signup_date  DATE NOT NULL
);

CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category_id   INT NOT NULL,
    price         DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id     INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT NOT NULL,
    order_date   DATE NOT NULL,
    status       ENUM('placed','shipped','delivered','cancelled') DEFAULT 'placed',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Helpful indexes for analytics-style queries
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);

-- ---------- Sample Data ----------

INSERT INTO categories (category_name) VALUES
('Electronics'),('Home & Kitchen'),('Books'),('Fashion'),('Sports');

INSERT INTO customers (name, email, city, signup_date) VALUES
('Aarav Sharma','aarav.s@example.com','Nagpur','2024-01-12'),
('Priya Iyer','priya.i@example.com','Pune','2024-02-03'),
('Rohan Mehta','rohan.m@example.com','Mumbai','2024-02-20'),
('Sneha Patil','sneha.p@example.com','Nagpur','2024-03-05'),
('Karan Verma','karan.v@example.com','Delhi','2024-03-18'),
('Anjali Nair','anjali.n@example.com','Bengaluru','2024-04-01'),
('Vivek Rao','vivek.r@example.com','Pune','2024-04-22'),
('Ishita Joshi','ishita.j@example.com','Nagpur','2024-05-10'),
('Manish Gupta','manish.g@example.com','Delhi','2024-05-28'),
('Divya Kulkarni','divya.k@example.com','Mumbai','2024-06-15');

INSERT INTO products (product_name, category_id, price) VALUES
('Wireless Earbuds',1,1999.00),
('Smartphone Stand',1,499.00),
('4K Monitor',1,15999.00),
('Bluetooth Speaker',1,2499.00),
('Non-stick Pan Set',2,1899.00),
('Electric Kettle',2,999.00),
('Vacuum Flask',2,599.00),
('Data Structures in Java',3,699.00),
('The Pragmatic Programmer',3,899.00),
('Mystery Novel Pack',3,599.00),
('Men Casual Shirt',4,899.00),
('Women Kurti',4,1199.00),
('Running Shoes',4,2999.00),
('Winter Jacket',4,3499.00),
('Yoga Mat',5,799.00),
('Dumbbell Set 10kg',5,2199.00),
('Cricket Bat',5,2599.00),
('Football',5,899.00),
('Laptop Backpack',1,1499.00),
('Smartwatch',1,4999.00);

INSERT INTO orders (customer_id, order_date, status) VALUES
(1,'2024-06-01','delivered'),(1,'2024-07-15','delivered'),
(2,'2024-06-05','delivered'),(2,'2024-08-02','shipped'),
(3,'2024-06-20','delivered'),(3,'2024-07-01','cancelled'),
(4,'2024-06-25','delivered'),(4,'2024-08-10','delivered'),
(5,'2024-07-03','delivered'),(5,'2024-07-28','shipped'),
(6,'2024-07-10','delivered'),(6,'2024-08-20','delivered'),
(7,'2024-07-18','delivered'),(7,'2024-09-01','placed'),
(8,'2024-08-01','delivered'),(8,'2024-09-05','delivered'),
(9,'2024-08-12','delivered'),(9,'2024-08-30','cancelled'),
(10,'2024-08-22','delivered'),(10,'2024-09-10','shipped');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,1,1,1999.00),(1,19,1,1499.00),
(2,3,1,15999.00),
(3,5,1,1899.00),(3,6,1,999.00),
(4,11,2,899.00),
(5,13,1,2999.00),
(6,20,1,4999.00),
(7,8,1,699.00),(7,9,1,899.00),
(8,4,1,2499.00),(8,7,2,599.00),
(9,15,1,799.00),(9,16,1,2199.00),
(10,2,3,499.00),
(11,17,1,2599.00),(11,18,2,899.00),
(12,12,1,1199.00),(12,14,1,3499.00),
(13,10,2,599.00),
(14,1,2,1999.00),
(15,3,1,15999.00),(15,19,1,1499.00),
(16,6,1,999.00),
(17,20,1,4999.00),
(18,5,1,1899.00),
(19,13,1,2999.00),(19,15,1,799.00),
(20,8,1,699.00);
