------------------------------------------------------iNeuron_SQL_Project - Assignment 1-----------------------------------------------------------
---------------------------------------------------SQL PROJECT - HIRING ABC COMPANY (Real Question)--------------------------------------------------
CREATE WAREHOUSE fsda;
USE WAREHOUSE fsda;

CREATE DATABASE assignment_1;
USE assignment_1;

CREATE SCHEMA assignment_1;
USE assignment_1;

-- Task 1
-- Write a SQL query that, for each 'product', returns the total amount of money spent on it

CREATE OR REPLACE TABLE shopping_history (
    product VARCHAR NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price INTEGER NOT NULL
);

INSERT INTO shopping_history 
VALUES ('milk',3,10),
       ('bread',7,3),
       ('bread',5,2),
       ('eggs',6,5),
       ('apples',2,100),
       ('apples',1,120),
       ('banana',12,6),
       ('water bottle',9,15),
       ('eggs',4,40),
       ('pastry',2,60);
       

select product, sum(quantity * unit_price) as total_price
from shopping_history
group by product
order by product desc;

-- Task 2
-- Write a SQL query that finds all clients who talked for atleast 10 mins in total?
CREATE OR REPLACE TABLE phones (
    name VARCHAR(20) NOT NULL UNIQUE,
    phone_number INTEGER NOT NULL UNIQUE
);

INSERT INTO phones 
VALUES ('Jack',1234),
       ('Lena',3333),
       ('Mark',9999),
       ('Anna',7582);

CREATE OR REPLACE TABLE calls (
    id INTEGER NOT NULL,
    caller INTEGER NOT NULL,
    callee INTEGER NOT NULL,
    duration INTEGER NOT NULL,
    UNIQUE(id)
);

INSERT INTO calls VALUES
(25,1234,7582,8),
(7,9999,7582,1),
(18,9999,3333,4),
(2,7582,3333,3),
(3,3333,1234,1),
(21,3333,1234,1);

select name from phones where phone_number IN
(select query_result.client from 
(select c1.caller as client, (nvl(d1,0) + nvl(d2,0)) as total_duration from
(select caller, sum(duration) as d1 from calls  group by caller) as c1 
left outer join
(select callee, sum(duration) as d2 from calls group by callee) as c2
on c1.caller = c2.callee
where total_duration >= 10) as query_result)
order by name; 

-- Now checking this query with different set of values
truncate calls;
truncate phones;

INSERT INTO phones 
VALUES ('John',6356),
       ('Addison',4315),
       ('Kate',8003),
       ('Ginny',9831);

INSERT INTO calls VALUES
(65,8003,9831,7),
(100,9831,8003,3),
(145,4315,9831,18); --  my query fails when a single call exceeds 10 mins, so use left outer join and nvl() to include that call

-- TASK 3
-- Write a SQL query that returns a table containing one column, balance. The table should contains one row with the
-- total balance of your account at the end of the year, including the fee for holding a credit card?
CREATE OR REPLACE TABLE transactions (
    amount INTEGER NOT NULL,
    date DATE NOT NULL
);

INSERT INTO transactions VALUES
(1000,'2020-01-06'),
(-10,'2020-01-14'),
(-75,'2020-01-20'),
(-5,'2020-01-25'),
(-4,'2020-01-29'),
(2000,'2020-03-10'),
(-75,'2020-03-12'),
(-20,'2020-03-15'),
(40,'2020-03-15'),
(-50,'2020-03-17'),
(200,'2020-10-10'),
(-200,'2020-10-10');

select sum(amount) from transactions; -- balance without credit card charge

-- 12*5 = 60 is the by default charge, look for number of exemption
-- only negative ones are the credit card transaction
select sum(amount) - (12 - 
(
  select count(*) from
    (
        select month(date) as month, count(*) as no_of_trans, sum(amount)*-1 as total_cost
        from transactions
        where amount < 0
        group by month(date)
    ) 
  where no_of_trans >= 3 and total_cost >= 100
)
                      ) * 5 as balance
from transactions;

Truncate transactions;

INSERT INTO transactions VALUES
(1,'2020-06-29'),
(35,'2020-02-20'),
(-50,'2020-02-03'),
(-1,'2020-02-26'),
(-200,'2020-08-01'),
(-44,'2020-02-07'),
(-5,'2020-02-25'),
(1,'2020-06-29'),
(1,'2020-06-29'),
(-100,'2020-12-29'),
(-100,'2020-12-30'),
(-100,'2020-12-31'); -- balance -612

INSERT INTO transactions VALUES
(6000,'2020-04-03'),
(5000,'2020-04-02'),
(4000,'2020-04-01'),
(3000,'2020-03-01'),
(2000,'2020-02-01'),
(1000,'2020-01-01'); -- balance: 20940