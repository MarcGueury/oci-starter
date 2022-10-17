-- DROP DATABASE db1;
show databases;
create database db1;
use db1;

-- DROP TABLE DEPT;
create table dept
       (deptno integer primary key,
        dname varchar(64),
        loc varchar(64) );

insert into dept values (10, 'ACCOUNTING', 'NEW YORK');
insert into dept values (20, 'RESEARCH',   'DALLAS');
insert into dept values (30, 'SALES',      'CHICAGO');
insert into dept values (40, 'OPERATIONS', 'BOSTON');
select * from dept;


