/* Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

sales
menu
members
You can inspect the entity relationship diagram and example data below.
*/

-- What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) from dbo.sales s 
join dbo.menu m on s.product_id = m.product_id 
group by s.customer_id

-- 2. How many days has each customer visited the restaurant?

select customer_id,COUNT(distinct order_date) from dbo.sales
group by customer_id


-- What was the first item from the menu purchased by each customer?
select distinct s.customer_id ,first_value(m.product_name) over(partition by s.customer_id order by s.order_date) from dbo.sales s 
join dbo.menu m on s.product_id = m.product_id


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
with highest_product as (
select customer_id,product_name,COUNT(*) as product_count from dbo.sales s join dbo.menu m on s.product_id = m.product_id
group by customer_id,product_name
)
select customer_id,product_name,product_count from 
(select customer_id,product_name,product_count,ROW_NUMBER() over(partition by customer_id order by product_count desc) as rn from highest_product) a
where rn=1


-- Which item was the most popular for each customer?

with product_cnt as (
select s.customer_id,product_name,count(product_name) product_cnt from dbo.sales s
 join dbo.menu m on s.product_id  = m.product_id
 GROUP BY s.customer_id,product_name

)
select customer_id ,product_name as most_popular_product from (
select *,ROW_NUMBER() OVER(partition by customer_id order by product_cnt desc) as rn from product_cnt

) a 
where rn=1

-- Which item was purchased first by the customer after they became a member?
with customer_data as (
select s.customer_id,product_id,DATEDIFF(day,order_date,join_date) as days ,ROW_NUMBER() OVER(partition by s.customer_id order by DATEDIFF(day,order_date,join_date)) as rn from dbo.sales  s join dbo.members  m on s.customer_id = m.customer_id and order_date <join_date
)
select customer_id,m.product_name from customer_data c join menu m on c.product_id = m.product_id
where rn=1


-- What is the total items and amount spent for each member before they became a member?
with customer_data as (
select s.customer_id,product_id,ROW_NUMBER() OVER(partition by s.customer_id order by DATEDIFF(day,order_date,join_date) desc ) as rn from dbo.sales  s join dbo.members  m on s.customer_id = m.customer_id and order_date <join_date
)
select customer_id,count(m.product_name) as total_product,SUM(price)as total_amount from customer_data c 
join menu m on c.product_id = m.product_id
GROUP BY customer_id

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with customer_data as (

select s.customer_id,product_id,ROW_NUMBER() OVER(partition by s.customer_id order by DATEDIFF(day,order_date,join_date) desc ) as rn from dbo.sales  s join dbo.members  m on s.customer_id = m.customer_id and order_date <join_date

)
select customer_id,sum(case when product_name='sushi' then 20 else 10 end )as points from customer_data c 
join menu m on c.product_id = m.product_id
GROUP BY customer_id





