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
    id INT NOT NULL,
    firstname VARCHAR2(40) NOT NULL,
    lastname VARCHAR2(20) NOT NULL,
    address VARCHAR2(70),
    city VARCHAR2(40),
    state VARCHAR2(40),
    country VARCHAR2(40),
    postalcode VARCHAR2(10),
    PRIMARY KEY  (id)
);
commit;
exit;