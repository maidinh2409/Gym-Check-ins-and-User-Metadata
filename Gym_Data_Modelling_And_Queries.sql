create database gym_data;

use gym_data;
drop table user_data;
create table user_data (
	user_id varchar(15) primary key,
    first_name varchar(20),
    last_name varchar(20),
    age int,
    gender varchar (15),
	birthdate varchar(20),
    signup_date varchar(20),
    user_location varchar(20),
	subscription_plan varchar(20)
);

create table checkin_out (
	user_id	varchar(15),
    gym_id	varchar(15),
    checkin_time	varchar(20),
    checkout_time	varchar(20),
    workout_type	varchar(20),
    calories_burned int
);

create table locations (
	gym_id	varchar(15) primary key,
    location	varchar(20),
    gym_type	varchar(20),
    facilities varchar(50)
);

create table subscription_plan (
	subscription_plan	varchar(15),
    price_per_month	float,
    features varchar(150)
);
select * from user_data;

-- sample of loading one table to db
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/subscription_plans.csv' 
INTO TABLE subscription_plan
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Create the checkin_id field for the checkin_out table, as the primary key
use gym_data;
alter table checkin_out
add checkin_id int not null auto_increment primary key;

use gym_data; 
select * from checkin_out;

-- Convert the data type to date for checkin_time, checkout_time, bdate, sign_update
select * from user_data;

alter table checkin_out
modify column checkin_time datetime;

alter table checkin_out
modify column checkout_time datetime;

	-- Reformat the columns birthdate and signupdate to match the DATE data type format and convert them to the Date data type

	alter table user_data
	add column birth_date date;

	alter table user_data
	add column signup_date date;

	update user_data
	set birth_date = CONCAT( 
			SUBSTRING(birthdate, -4),
			"-", 
			if (
			LENGTH(SUBSTRING(birthdate, 1, LOCATE('/', birthdate) - 1)) = 1, 
			CONCAT("0",SUBSTRING(birthdate, 1, LOCATE('/', birthdate) - 1)),
			SUBSTRING(birthdate, 1, LOCATE('/', birthdate) - 1)
			),
			"-",
			if (
			LENGTH(SUBSTRING(birthdate, LOCATE('/', birthdate) + 1, LOCATE('/', birthdate, LOCATE('/', birthdate) + 1) - LOCATE('/', birthdate) - 1)) = 1, 
			CONCAT("0",SUBSTRING(birthdate, LOCATE('/', birthdate) + 1, LOCATE('/', birthdate, LOCATE('/', birthdate) + 1) - LOCATE('/', birthdate) - 1)),
			SUBSTRING(birthdate, LOCATE('/', birthdate) + 1, LOCATE('/', birthdate, LOCATE('/', birthdate) + 1) - LOCATE('/', birthdate) - 1)
			) 
		);

	update user_data
	set signup_date = CONCAT( 
			SUBSTRING(sign_up_date, -4),
			"-", 
			if (
			LENGTH(SUBSTRING(sign_up_date, 1, LOCATE('/', sign_up_date) - 1)) = 1, 
			CONCAT("0",SUBSTRING(sign_up_date, 1, LOCATE('/', sign_up_date) - 1)),
			SUBSTRING(sign_up_date, 1, LOCATE('/', sign_up_date) - 1)
			),
			"-",
			if (
			LENGTH(SUBSTRING(sign_up_date, LOCATE('/', sign_up_date) + 1, LOCATE('/', sign_up_date, LOCATE('/', sign_up_date) + 1) - LOCATE('/', sign_up_date) - 1)) = 1, 
			CONCAT("0",SUBSTRING(sign_up_date, LOCATE('/', sign_up_date) + 1, LOCATE('/', sign_up_date, LOCATE('/', sign_up_date) + 1) - LOCATE('/', sign_up_date) - 1)),
			SUBSTRING(sign_up_date, LOCATE('/', sign_up_date) + 1, LOCATE('/', sign_up_date, LOCATE('/', sign_up_date) + 1) - LOCATE('/', sign_up_date) - 1)
			) 
		);

	-- Drop the old columns

	alter table user_data
	drop column birthdate,
	drop column sign_up_date;
    

use gym_data;
alter table user_data
add column subscriptionCode varchar(10);

alter table subscription_plan
add column subscriptionCode varchar(10);

-- Encode the subscription_plan table
UPDATE subscription_plan
SET subscriptionCode = 'PLAN01'
WHERE REPLACE(REPLACE(REPLACE(subscription_plan, '\r', ''), '\n', ''), '\t', '') = 'Basic';

UPDATE subscription_plan
SET subscriptionCode = 'PLAN02'
WHERE REPLACE(REPLACE(REPLACE(subscription_plan, '\r', ''), '\n', ''), '\t', '') = 'Pro';

UPDATE subscription_plan
SET subscriptionCode = 'PLAN03'
WHERE REPLACE(REPLACE(REPLACE(subscription_plan, '\r', ''), '\n', ''), '\t', '') = 'Student';

alter table subscription_plan
add constraint PK_subscription_plan PRIMARY KEY (subscriptionCode);

-- Encode the user_data table
UPDATE user_data
SET subscriptionCode = 'PLAN01'
WHERE REPLACE(REPLACE(REPLACE(subscription_plan, '\r', ''), '\n', ''), '\t', '') = 'Basic';

UPDATE user_data
SET subscriptionCode = 'PLAN02'
WHERE REPLACE(REPLACE(REPLACE(subscription_plan, '\r', ''), '\n', ''), '\t', '') = 'Pro';

UPDATE user_data
SET subscriptionCode = 'PLAN03'
WHERE REPLACE(REPLACE(REPLACE(subscription_plan, '\r', ''), '\n', ''), '\t', '') = 'Student';

-- Drop the subscription column because it contains unclean data

alter table user_data
drop column subscription_plan;

-- Set primary key, foreign key, constraints for all tables;

use gym_data;
alter table checkin_out
add constraint FK1_checkin_out FOREIGN KEY (user_id) references user_data(user_id),
add constraint FK2_checkin_out FOREIGN KEY (gym_id) references locations(gym_id);

use gym_data;
alter table user_data
add constraint FK1_user_data foreign key(subscriptionCode) references subscription_plan(subscriptionCode);

## ANALYTICS QUESTIONS?

-- What is the revenue generated by the gym in each plan/region/total?
	-- Assume that the user's subscription is calculated from the month the user starts their subscription until the present.
	-- Assume that no user cancels their subscription


	-- Monthly Revenue
		-- Monthly revenue = revenue from new users;
		-- Cummulative revenue over months = total monthly revenue
			-- --> TOTAL REVENUE OVER TIME = SUM(Cummulative revenue over months)
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(u.signup_date) AS `year`,
        MONTH(u.signup_date) AS `month`,
        SUM(p.price_per_month) AS monthly_revenue
    FROM user_data AS u
    JOIN subscription_plan AS p 
        ON p.subscriptionCode = u.subscriptionCode
    WHERE u.signup_date BETWEEN '2020-01-01' AND CURDATE()  
    GROUP BY YEAR(u.signup_date), MONTH(u.signup_date)
)
SELECT 
    mr.year,
    mr.month,
    CONCAT(mr.year, mr.month),
    mr.monthly_revenue,
    -- Cumulative revenue: Doanh thu tích lũy là doanh thu tháng trước cộng với doanh thu của tháng này
    (SELECT SUM(mr1.monthly_revenue)
     FROM MonthlyRevenue mr1
     WHERE mr1.year < mr.year OR (mr1.year = mr.year AND mr1.month <= mr.month)
    ) AS cumulative_revenue
FROM MonthlyRevenue mr
ORDER BY mr.year, mr.month;
	-- Monthly Revenue
    

	-- Total revenue by Subscription plan

select 
	p.sub_plan as `subscription_plan`,
    CONCAT('$', FORMAT(SUM(timestampdiff(MONTH,  u.signup_date, current_date()) * p.price_per_month), 2)) as `Total Revenue`
from user_data as u
join subscription_plan as p on p.subscriptionCode = u.subscriptionCode
group by p.sub_plan;

	-- Total revenue by user_locations
SELECT
    SUM(c.TotalRevenue) AS TotalRevenueSum
FROM (
    SELECT 
        u.user_location,
        SUM((TIMESTAMPDIFF(MONTH, u.signup_date, '2023-10-31') + 1) * p.price_per_month) AS TotalRevenue
    FROM user_data AS u
    JOIN subscription_plan AS p 
        ON p.subscriptionCode = u.subscriptionCode
    GROUP BY u.user_location
) AS c;

    SELECT 
        u.user_location,
        u.subscriptionCode,
        p.subscription_plan,
        SUM((TIMESTAMPDIFF(MONTH, u.signup_date, '2023-10-31') + 1) * p.price_per_month) AS TotalRevenue
    FROM user_data AS u
    JOIN subscription_plan AS p 
        ON p.subscriptionCode = u.subscriptionCode
    GROUP BY u.user_location, u.subscriptionCode;


	-- Total revenue in a given period of time
    
drop function FNC_TOTAL_REV;

DELIMITER $$

CREATE FUNCTION FNC_TOTAL_REV (
    startDate DATE,
    endDate DATE
) RETURNS DECIMAL(18,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE totalRev DECIMAL(18,2) DEFAULT 0;

    SET totalRev = (
        SELECT SUM(cumulative_revenue)
        FROM (
            SELECT 
                mr.year,
                mr.month,
                mr.monthly_revenue,
                (SELECT SUM(mr1.monthly_revenue)
                 FROM (
                    SELECT 
                        YEAR(u.signup_date) AS `year`,
                        MONTH(u.signup_date) AS `month`,
                        SUM(p.price_per_month) AS monthly_revenue
                    FROM user_data AS u
                    JOIN subscription_plan AS p 
                        ON p.subscriptionCode = u.subscriptionCode
                    WHERE u.signup_date BETWEEN startDate AND endDate
                    GROUP BY YEAR(u.signup_date), MONTH(u.signup_date)
                 ) AS mr1
                 WHERE mr1.year < mr.year OR (mr1.year = mr.year AND mr1.month <= mr.month)
                ) AS cumulative_revenue
            FROM (
                SELECT 
                    YEAR(u.signup_date) AS `year`,
                    MONTH(u.signup_date) AS `month`,
                    SUM(p.price_per_month) AS monthly_revenue
                FROM user_data AS u
                JOIN subscription_plan AS p 
                    ON p.subscriptionCode = u.subscriptionCode
                WHERE u.signup_date BETWEEN startDate AND endDate
                GROUP BY YEAR(u.signup_date), MONTH(u.signup_date)
            ) AS mr
        ) AS cumulativeResults
    );

    RETURN totalRev;
END $$

DELIMITER ;


SELECT FNC_TOTAL_REV('2021-01-01', curdate()) AS TotalRevenue;

	-- Revenue by locations
	SELECT 
			u.user_location,
			SUM((TIMESTAMPDIFF(MONTH, u.signup_date, '2023-10-31') + 1) * p.price_per_month) AS TotalRevenue
		FROM user_data AS u
		JOIN subscription_plan AS p 
			ON p.subscriptionCode = u.subscriptionCode
		GROUP BY u.user_location;
    
    -- Revenue by plan
    
    SELECT
        u.subscriptionCode,
        SUM((TIMESTAMPDIFF(MONTH, u.signup_date, '2023-10-31') + 1) * p.price_per_month) AS TotalRevenue
    FROM user_data AS u
    JOIN subscription_plan AS p 
        ON p.subscriptionCode = u.subscriptionCode
    GROUP BY u.subscriptionCode;

-- Which customer segment is the most popular?

	-- By age group

	select 
		case 
			when age >=60 and age<= 78 then '60-78 (Baby Boomers)'
			when age >=44 and age<= 59 then '44-59 (Gen X)'
			when age >=28 and age<= 43 then '28-43 (Gen Y)'
			when age >=12 and age<= 27 then '12-27 (Gen Z)'
			else 'Others'
		end as `age_group`,
		count(*) as `Number of users`
	from user_data
	group by `age_group`
	order by `Number of users` desc;
    
	-- By gender
    
    select 
		gender,
		count(*) as `Number of users`
	from user_data
	group by gender
	order by `Number of users` desc;


-- Which locations have the highest customer density?

	select  
		l.location,
		l.gym_type,
		count(*) as `Total checkin`
	from checkin_out as c
	join locations as l on l.gym_id = c.gym_id
	group by l.location, l.gym_type
	order by `Total checkin` desc;
    
-- Who are the top 10 customers who have spent the most time working out?
use gym_data;
select 
	c.user_id,
    concat(u.first_name, " ", u.last_name) as `Full Name`,
    sum(timestampdiff(hour, c.checkin_time, c.checkout_time)) as `Total hours spent`,
    format(sum(c.calories_burned),0) as `Calories burned`
from checkin_out as c
join user_data as u on u.user_id = c.user_id
group by c.user_id, `Full Name`
order by `Total hours spent` desc
limit 10;



