# Query 1

select   market 
		from dim_customer 
		where region= "APAC"
        and customer = 'Atliq Exclusive'
        ;


# Query 2    

WITH unique_product_2020(unique_products_2020) as 
(
	select  count(distinct product_code) 
		from fact_sales_monthly 
		where fiscal_year = '2020'
),
unique_product_2021(unique_products_2021) as 
(
	select  count(distinct product_code) 
		from fact_sales_monthly 
		where fiscal_year = '2021'
)

select 	t.unique_products_2020 , 
		o.unique_products_2021 ,
        round((o.unique_products_2021-t.unique_products_2020)*100/t.unique_products_2020,2) perc_chg
        from unique_product_2020 as t, 
        unique_product_2021 as o;
        
        
        
    
#Qeury 3
select  segment, 
		count( distinct product_code) as product_count 
		from dim_product 
		group by 1 
		order by 2 desc;
		

#Query 4

with product_count_2020 as 
(
	select
		p.segment segment,
		count(distinct s.product_code) as product_count_2020 
        from fact_sales_monthly s
		join dim_product p on p.product_code = s.product_code
		where fiscal_year = '2020'
		group by 1
),
 
product_count_2021 as 
(
	select
		p.segment segment,
		count(distinct s.product_code) as product_count_2021 
        from fact_sales_monthly s
		join dim_product p on p.product_code = s.product_code
		where fiscal_year = '2021'
		group by 1
 )
 select 
		o.segment,
		z.product_count_2020 ,
		o.product_count_2021 ,
        o.product_count_2021-z.product_count_2020 as difference,
      round((  o.product_count_2021-z.product_count_2020)*100 / z.product_count_2020,2) as jump_prct
		from product_count_2020 z
		join product_count_2021 o on o.segment = z.segment;



            
#Query 5

select  c.product_code ,
		p.product,
        c.manufacturing_cost
		from fact_manufacturing_cost c 
        join dim_product p on c.product_code = p.product_code
        where c.manufacturing_cost =(select min(manufacturing_cost) from fact_manufacturing_cost)
		
union all        

select  c.product_code ,
		p.product,
        c.manufacturing_cost
        from fact_manufacturing_cost c 
        join dim_product p on c.product_code = p.product_code
        where c.manufacturing_cost =(select max(manufacturing_cost) from fact_manufacturing_cost)
		;
        

# Query 6   problem with average it is calculating average of returned values

select * from fact_pre_invoice_deductions;

select  
		d.customer_code , 
		c.customer ,
       round( (select avg( pre_invoice_discount_pct ) from fact_pre_invoice_deductions)*100,2 )average_discount_percentage,
        round((d.pre_invoice_discount_pct)*100,2 )as discount_given
		from fact_pre_invoice_deductions d
		join dim_customer c on c.customer_code = d.customer_code
		where 
        (
				d.pre_invoice_discount_pct > (select avg( pre_invoice_discount_pct ) 
												from fact_pre_invoice_deductions ) 
				and 
				fiscal_year = '2021'
                and 
                c.market = 'India'
		)
		order by discount_given desc
		limit 5;
        


        
# Query 7   ( Observation : Atliq Exclusive has multiple Customer_ID

Select 
		month(date(s.date)) as Month,
		year(date(s.date)) as Year,
        sum(s.sold_quantity*g.gross_price) as Gross_Sale_Amount
		from dim_customer c  
		join fact_sales_monthly s on  s.customer_code = c.customer_code
		join fact_gross_price g on g.product_code = s.product_code
		where c.customer = 'Atliq Exclusive'
		group by 1,2
		order by 2,1
;


# Query 8 


Select 
		
		case 
			when  month(s.date) between 10 and 12 then '1' 
            when  month(s.date) between 1 and 3 then '2'
            when  month(s.date) between 4 and 7 then '3'
            when  month(s.date) between 8 and 12 then '4'
		end as quarter,
        sum(s.sold_quantity) as total_sold_quantity
		from fact_sales_monthly s
        where s.fiscal_year = '2020'
		group by 1
		order by total_sold_quantity desc
;




#Query 9

with sales_by_channel  as
(
	select  c.channel as channel,
			sum(s.sold_quantity) as gross_sale,
			(sum(s.sold_quantity)/(select sum(sold_quantity) from fact_sales_monthly where fiscal_year = '2021'))*100 as percentage
			from dim_customer c
			join fact_sales_monthly s on s.customer_code = c.customer_code
							#  cross join (select sum(sold_quantity) as s from fact_sales_monthly where fiscal_year = '2021') cj
			where s.fiscal_year = '2021'
			group by 1
)

select  channel,
		gross_sale,
        percentage
		from sales_by_channel 
		where gross_sale = ( select max(gross_sale) from sales_by_channel)
;




-- Query 10
with cte as 
(
	select  p.division as Division,
		p.product_code as product_code,
        p.product as product,
		sum(s.sold_quantity) /*over( partition by p.division, p.product_code)*/ total_sold_quantity

		from dim_product p
		left join fact_sales_monthly s on s.product_code = p.product_code
		where s.fiscal_year = '2021'
		group by 1,2
)

select * from 
(
select  Division,
		product_code,
        product,
        total_sold_quantity,
        row_number() over( partition by Division order by total_sold_quantity desc) as rank_mark

		from cte
) ranks 
where rank_mark <= 3;

