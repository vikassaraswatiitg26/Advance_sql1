show databases;

/* New database name "retail_store" is been created and the data is been imported 
via data import wizard and before importing column name have been modifed in excel */


use retail_store;

/* Three different tables are been imported name store_data,product_data1,inventory which are been created in excel

  Created new column in store_data : store_id
  - Format: StoreCode_Region (e.g., 'S001_N', 'S001_S')

  Created new column in product_data1 : store_region_product_id
  - Format: StoreCode_Region_ProductCode (e.g., 'S001_N_P001', 'S001_N_P012')
  
  These were added to help uniquely identify store-region and product combinations.
*/

show tables;

select * from product_data1;

ALTER TABLE store_data
MODIFY store_Region_ID VARCHAR(50);


alter table store_data
add primary key(Store_Region_ID);

ALTER TABLE product_data1
MODIFY Store_Region_Product_ID VARCHAR(50);

alter table product_data1
add primary key(store_Region_Product_ID);

ALTER TABLE inventory_data
MODIFY Store_Region_Product_ID VARCHAR(50);

ALTER TABLE inventory_data
MODIFY Store_Region_ID VARCHAR(50);

ALTER TABLE inventory_data
ADD CONSTRAINT fk_inventory_store
FOREIGN KEY (Store_Region_ID)
REFERENCES Store_data(store_Region_ID);

ALTER TABLE inventory_data
ADD CONSTRAINT fk_inventory_product
FOREIGN KEY (Store_Region_Product_ID)
REFERENCES product_data1(store_Region_Product_ID);

select * from inventory_data;


use retail_store;
show tables;

alter table product_data1 rename to product;
alter table store_data rename to store;
alter table inventory_data rename to inventory;

show tables;

/* Queries for the Stock level Calculation */

with A as 
(
select s.Store_region_ID,
	   s.Store_ID,
       s.Region,
       sum(i.Inventory_Level) as Stock_Level
from store as s
join inventory as i on i.Store_region_ID=s.Store_Region_ID
group by s.Store_Region_ID
)

select Store_ID,Region,Stock_Level from A
order by Stock_Level desc;

/* Query for lag_days*/

with reorder_flags as 
(
  select *,
  case   
       when Inventory_level<Demand_Forecast then 'YES'
       else 'NO'
       end as Reorder_trigger
from inventory
),

dated_lags as 
(select 
        Store_Region_Product_ID,
        `date`,
        Inventory_Level,
        Demand_Forecast,
        lag(str_to_date(`Date`,'%d-%m-%Y')) over(partition by Store_Region_Product_ID order by str_to_date(`Date`,'%d-%m-%Y')) as prev_date,
        datediff(str_to_date(`Date`,'%d-%m-%Y'),lag(str_to_date(`Date`,'%d-%m-%Y')) over(partition by Store_Region_Product_ID order by str_to_date(`Date`,'%d-%m-%Y'))) as lag_days
from reorder_flags

)
select * from dated_lags;

/*Query for Reorder_Point and Stock_status*/


with reorder_flags as 
(
  select *,
  case   
       when Inventory_level<Demand_Forecast then 'YES'
       else 'NO'
       end as Reorder_trigger
from inventory
),

dated_lags as 
(select 
        Store_Region_Product_ID,
        `date`,
        Inventory_Level,
        Demand_Forecast,
        lag(str_to_date(`Date`,'%d-%m-%Y')) over(partition by Store_Region_Product_ID order by str_to_date(`Date`,'%d-%m-%Y')) as prev_date,
        datediff(str_to_date(`Date`,'%d-%m-%Y'),lag(str_to_date(`Date`,'%d-%m-%Y')) over(partition by Store_Region_Product_ID order by str_to_date(`Date`,'%d-%m-%Y'))) as lag_days
from reorder_flags
), 

avg_lag_model as 
(
select 
        Store_region_Product_ID,
        round(Avg(lag_days)) as avg_lag_days
from dated_lags
where lag_days is not null
group by Store_Region_Product_ID 
)

select 
   i.`date`,
   i.Store_Region_ID,
   i.store_Region_Product_ID,
   i.Inventory_Level,
   i.Demand_Forecast,
   Coalesce(a.avg_lag_days,7) as avg_lag_days,
   round((i.Demand_Forecast*coalesce(a.avg_lag_days,7))) as Reorder_Point,
   case
       when i.Inventory_Level<(i.Demand_Forecast*Coalesce(a.avg_lag_days,7))
       then 'Low Inventory'
       else 'Sufficient Inventory'
   end as Stock_status 
from inventory as i
left join 
  avg_lag_model as a on i.Store_Region_Product_ID=a.Store_Region_Product_ID
order by
  i.Store_Region_Product_ID,str_to_date(i.`Date`,'%d-%m-%Y');
       


/* Query for Inventory_turnover */

select
       Store_Region_Product_ID,
       round(sum(Units_Sold)/avg(Inventory_Level))  as Inventory_turnover
from inventory
group by 
 Store_Region_Product_ID
 order by Inventory_turnover desc;

select * from inventory;

/* Query for stockout_days,stockout_rate,Avg_stock_levels,Inventory_Age*/

select
      Store_Region_Product_ID,
      count(*) as Total_records,
      sum(case when Inventory_Level<Demand_Forecast then 1 else 0 end) as stockout_days,
      round(100*sum(case when Inventory_Level<Demand_Forecast then 1 else 0 end)/count(*),2) as Stockout_rate,
      round(avg(Inventory_level),2) as Avg_stock_levels,
      round(avg(Inventory_Level)/nullif(Avg(Demand_Forecast),0),1) as Inventory_Age
from 
     inventory
group by 
     Store_Region_Product_ID
Order by 
    Total_records desc, Stockout_rate desc;


/* view is created for Dashboard*/

create view reorder_analysis as 
with reorder_flags as 
(
  select *,
  case   
       when Inventory_level<Demand_Forecast then 'YES'
       else 'NO'
       end as Reorder_trigger
from inventory
),

dated_lags as 
(select 
        Store_Region_Product_ID,
        `date`,
        Inventory_Level,
        Demand_Forecast,
        lag(str_to_date(`Date`,'%d-%m-%Y')) over(partition by Store_Region_Product_ID order by str_to_date(`Date`,'%d-%m-%Y')) as prev_date,
        datediff(str_to_date(`Date`,'%d-%m-%Y'),lag(str_to_date(`Date`,'%d-%m-%Y')) over(partition by Store_Region_Product_ID order by str_to_date(`Date`,'%d-%m-%Y'))) as lag_days
from reorder_flags
), 

avg_lag_model as 
(
select 
        Store_region_Product_ID,
        round(Avg(lag_days)) as avg_lag_days
from dated_lags
where lag_days is not null
group by Store_Region_Product_ID 
)

select 
   i.`date`,
   i.Store_Region_ID,
   i.store_Region_Product_ID,
   i.Inventory_Level,
   i.Demand_Forecast,
   Coalesce(a.avg_lag_days,7) as avg_lag_days,
   round((i.Demand_Forecast*coalesce(a.avg_lag_days,7))) as Reorder_Point,
   case
       when i.Inventory_Level<(i.Demand_Forecast*Coalesce(a.avg_lag_days,7))
       then 'Low Inventory'
       else 'Sufficient Inventory'
   end as Stock_status 
from inventory as i
left join 
  avg_lag_model as a on i.Store_Region_Product_ID=a.Store_Region_Product_ID
order by
  i.Store_Region_Product_ID,str_to_date(i.`Date`,'%d-%m-%Y');




