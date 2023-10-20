CREATE TABLE account
(
    customer_id INT NOT NULL PRIMARY KEY,
    fname VARCHAR(40) NOT NULL,
    lname VARCHAR(20) NOT NULL,
    address VARCHAR(70),
    city VARCHAR(40),
    state VARCHAR(40),
    country VARCHAR(40),
    postal_code VARCHAR(10)
);

CREATE TABLE cartitems
(
    item_id VARCHAR(8) NOT NULL PRIMARY KEY,
    customer_id INT NOT NULL,
    name VARCHAR(40) NOT NULL,
    price NUMERIC(10,2) NOT NULL
);