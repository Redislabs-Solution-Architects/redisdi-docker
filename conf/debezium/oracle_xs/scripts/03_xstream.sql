/* Set up XStreams */
alter system set db_recovery_file_dest_size = 1G;
alter system set db_recovery_file_dest = '/opt/oracle/oradata/recovery_area' scope=spfile;
alter system set enable_goldengate_replication=true;
shutdown immediate
startup mount
alter database archivelog;
alter database open;

alter session set container=orclpdb1;

ALTER TABLE CHINOOK.ALBUM ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.ARTIST ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.CUSTOMER ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.EMPLOYEE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.GENRE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.INVOICE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.INVOICELINE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.MEDIATYPE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.PLAYLIST ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.PLAYLISTTRACK ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE CHINOOK.TRACK ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

alter session set container=cdb$root;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_adm_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

alter session set container=orclpdb1;

CREATE TABLESPACE xstream_adm_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/xstream_adm_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

alter session set container=cdb$root;
CREATE USER c##dbzadmin IDENTIFIED BY dbz
    DEFAULT TABLESPACE xstream_adm_tbs
    QUOTA UNLIMITED ON xstream_adm_tbs
    CONTAINER=ALL;
GRANT CREATE SESSION, SET CONTAINER TO c##dbzadmin CONTAINER=ALL;
BEGIN
     DBMS_XSTREAM_AUTH.GRANT_ADMIN_PRIVILEGE(
        grantee                 => 'c##dbzadmin',
        privilege_type          => 'CAPTURE',
        grant_select_privileges => TRUE,
        container               => 'ALL'
     );
END;
/
CREATE TABLESPACE xstream_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/xstream_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
alter session set container=orclpdb1;
CREATE TABLESPACE xstream_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/xstream_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

alter session set container=cdb$root;
CREATE USER c##dbzuser IDENTIFIED BY dbz
    DEFAULT TABLESPACE xstream_tbs
    QUOTA UNLIMITED ON xstream_tbs
    CONTAINER=ALL;

GRANT CREATE SESSION TO c##dbzuser CONTAINER=ALL;
GRANT SET CONTAINER TO c##dbzuser CONTAINER=ALL;
GRANT SELECT ON V_$DATABASE to c##dbzuser CONTAINER=ALL; 
GRANT FLASHBACK ANY TABLE TO c##dbzuser CONTAINER=ALL;
GRANT SELECT_CATALOG_ROLE TO c##dbzuser CONTAINER=ALL;
GRANT EXECUTE_CATALOG_ROLE TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ANY TABLE TO c##dbzuser CONTAINER=ALL;
GRANT LOCK ANY TABLE TO c##dbzuser CONTAINER=ALL;

CONNECT c##dbzadmin/dbz@ORCLCDB;
DECLARE
  tables  DBMS_UTILITY.UNCL_ARRAY;
  schemas DBMS_UTILITY.UNCL_ARRAY;
BEGIN
    tables(1)  := NULL;
    schemas(1) := NULL;
  DBMS_XSTREAM_ADM.CREATE_OUTBOUND(
    server_name     =>  'dbzxout',
    table_names     =>  tables,
    schema_names    =>  schemas);
END;
/
BEGIN
  DBMS_XSTREAM_ADM.ALTER_OUTBOUND(
    server_name  => 'dbzxout',
    connect_user => 'c##dbzuser');
END;
/