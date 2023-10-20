alter session set container=orclpdb1;
ALTER SESSION SET NLS_LANGUAGE=American; 

CREATE USER accountdb
IDENTIFIED BY Password1
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA 10M ON users;

GRANT connect to accountdb;
GRANT resource to accountdb;
GRANT create session TO accountdb;
GRANT create table TO accountdb;
GRANT create view TO accountdb;

CONNECT accountdb/Password1@orclpdb1;

CREATE TABLE account
(
    customerid INT NOT NULL,
    fname VARCHAR2(40) NOT NULL,
    lname VARCHAR2(20) NOT NULL,
    address VARCHAR2(70),
    city VARCHAR2(40),
    state VARCHAR2(40),
    country VARCHAR2(40),
    postalcode VARCHAR2(10),
    PRIMARY KEY  (customerid)
);

CREATE TABLE cartitems 
(
    itemid VARCHAR2(8) NOT NULL, 
    customerid INT NOT NULL, 
    name VARCHAR2(40) NOT NULL, 
    price NUMERIC(10,2) NOT NULL, 
    PRIMARY KEY (itemid)
);

commit;
exit;