USE POS

/**********Data Prepration and Understanding**********/
 
--Q1 What is the total number of rows in each of the 3 tables in the database?
	
	select sum(Count_Cus) Total_Records from(
	select count(*) Count_Cus from Customer
	union all
	select count(*) Trans_Count from Transactions
	union all
	select count(*) Pod_Count from prod_cat_info) abc

--Q2 What is the total number of transactions that have a return?
	
	Select Count(*) Returned from Transactions
	where Qty < 1		

--Q3 As you would have noticed, the dates provided across the datasets are not in a correct format. 
--   As first steps, pls convert the date variables into valid date formats before proceeding ahead.
	
	alter table customer alter column Dob date
	alter table transactions alter column tran_date date

--Q4 What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.
	 
	 select * from
		(select top 1 year(tran_date) YYYY, month(tran_date) MM, day(tran_date) DD
		from Transactions
		order by YYYY desc, MM desc, dd desc
		
		union all	
		
		select top 1 year(tran_date) YYYY, month(tran_date) MM, day(tran_date) DD
		from Transactions
		order by YYYY , MM , dd)abc

--Q5 Which product category does the sub-category “DIY” belong to?
	 select prod_cat 
	 from prod_cat_info
	 where prod_subcat = 'DIY'

/**********************************************************************************************************************************************************************/

/************************** Data Analysis **************************/

--Q1 Which channel is most frequently used for transactions?

	 select top 1 abc.Store_type, max(store_count) max_transaction from
	 (select store_type, count( store_type) Store_count
 	 from Transactions
	 group by Store_type) abc
	 group by abc.Store_type
	 order by max_transaction desc

--Q2 What is the count of Male and Female customers in the database?
	
	 select gender, count(gender) Gen_Count
	 from Customer
	 group by Gender
	 having gender = 'f' or gender = 'm'

--Q3 From which city do we have the maximum number of customers and how many?
	 
	 select top 1 abc.city_code, max(cust_count)max_cust from(
	 select city_code, count(customer_Id) cust_count from Customer a 
	 group by city_code)abc
	 group by abc.city_code
	 order by max_cust desc

--Q4 How many sub-categories are there under the Books category?
 
	 select prod_cat, count(prod_subcat) subcat
	 from prod_cat_info
	 where prod_cat = 'Books'
	 group by prod_cat

--Q5 What is the maximum quantity of products ever ordered?
	 
	 select max(Qty)
	 from Transactions

--Q6 What is the net total revenue generated in categories Electronics and Books?
 
 select b.prod_cat, round(sum(total_amt),0) Total_revenue
 from Transactions a
 join prod_cat_info b
 on a.prod_cat_code = b.prod_cat_code
 where b.prod_cat = 'Books' or b.prod_cat = 'Electronics'
 group by b.prod_cat

--Q7 How many customers have >10 transactions with us, excluding returns?

	 select * from 
	 (select b.customer_Id, count(a.transaction_id) Transaction_count
	 from Transactions a
	 join Customer b
	 on a.cust_id = b.customer_Id
	 where a.Qty > 0
	 group by b.customer_Id) abc
	 where transaction_count > 10

--Q8 What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
 
	 select round(sum(total_amt),0) Total_revenue
	 from Transactions a
	 join prod_cat_info b
	 on a.prod_cat_code = b.prod_cat_code
	 where b.prod_cat = 'Clothing' or b.prod_cat = 'Electronics'
		  and
		  a.Store_type = 'Flagship stores'

--Q9 What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.
	 
	 select b.prod_subcat, round(sum(total_amt),0) Total_revenue
	 from Transactions a
	 join prod_cat_info b
	 on a.prod_cat_code = b.prod_cat_code and b.prod_cat = 'electronics' 
	 join customer c
	 on a.cust_id = c.customer_Id and c.Gender = 'M'
	 group by b.prod_subcat

--Q10 What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

	with abc as (
	select b.prod_subcat, round((sum(a.total_amt)/ (select sum(total_amt) from Transactions where total_amt < 0) )*100,0) Return_precent
	from Transactions a 
	join prod_cat_info b on a.prod_subcat_code=b.prod_sub_cat_code and a.prod_cat_code=b.prod_cat_code
	where a.total_amt <0
	group by b.prod_subcat)

	, xyz as(

	select top 5 b.prod_subcat, round((sum(a.total_amt)/ (select sum(total_amt) from Transactions where total_amt > 0) )*100,0) Sales_percent
	from Transactions a 
	join prod_cat_info b on a.prod_subcat_code=b.prod_sub_cat_code and a.prod_cat_code=b.prod_cat_code
	where a.total_amt >0
	group by b.prod_subcat
	order by Sales_percent desc)

	select x.prod_subcat, x.Return_precent, y.sales_percent from abc x
	right join xyz y on x.prod_subcat=y.prod_subcat
	group by x.prod_subcat, x.Return_precent, y.sales_percent

--Q11 For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions
--    from max transaction date available in the data?

	select sum(abc.total_amt) from(
	select b.transaction_id ,b.total_amt, b.tran_date, a.DOB, DATEDIFF(year, Dob, max(b.tran_date)) Age, max(b.tran_date) t_date
	from Customer a
	join Transactions b 
	on a.customer_Id = b.cust_id
	group by b.total_amt, b.tran_date, a.DOB, b.transaction_id
	) abc
	where Age between 25 and 35
	and tran_date >= dateadd(day, -30, t_date)


--Q12 Which product category has seen the max value of returns in the last 3 months of transactions?
	  select top 1 xyz.prod_cat, total_return from(
		select abc.prod_cat, sum(count_retrun)total_return from(
			select top 90 a.tran_date ,b.prod_cat,count(a.qty) count_retrun from Transactions a 
			join prod_cat_info b on a.prod_cat_code=b.prod_cat_code
			where qty < 0 
			group by b.prod_cat, a.tran_date
			order by a.tran_date desc)abc
		group by prod_cat) xyz
	  group by xyz.prod_cat, total_return
	  order by total_return desc


--Q13 Which store-type sells the maximum products; by value of sales amount and by quantity sold?

	 select top 1 Store_type, total_amt, total_qty from(
	 select Store_type, round(sum(total_amt),0) total_amt, round(sum(Qty),0) total_qty from Transactions 
	 group by Store_type) abc
	 group by total_amt, Store_type, total_qty
	 order by total_amt desc

--Q14 What are the categories for which average revenue is above the overall average.

	 select prod_cat from (
	 select b.prod_cat, round(avg(a.total_amt),0)Avg_revenue from Transactions a 
	 join prod_cat_info b on a.prod_cat_code=b.prod_cat_code
	 group by b.prod_cat) abc
	 where Avg_revenue > (select round(avg(total_amt),0) Overall_Avg_rev from transactions)

--Q15 Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

with abc as(
select top 5 b.prod_cat, sum(Qty)Qty_Sold  from Transactions a
join prod_cat_info b on a.prod_cat_code=b.prod_cat_code 
group by b.prod_cat
order by Qty_Sold desc) 

, xyz as (

select  b.prod_cat, b.prod_subcat, round(sum(a.total_amt),0)tota_rev, round(AVG(a.total_amt),0)Avg_rev from Transactions a 
join prod_cat_info b on a.prod_cat_code=b.prod_cat_code
group by b.prod_subcat, b.prod_cat)

select x.prod_cat, y.prod_subcat, x.Qty_Sold, y.tota_rev, y.Avg_rev from abc x
join xyz y on x.prod_cat=y.prod_cat
group by x.prod_cat, y.prod_subcat, x.Qty_Sold, y.tota_rev, y.Avg_rev 
