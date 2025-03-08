/**

data cleaning, cafe sales

Karter Wasberg

**/

/**

check for duplicate transaction id's 

**/

select count([transaction id]) from dbo.dirty_cafe_sales$;

select distinct [transaction id] from dbo.dirty_cafe_sales$;





/**

remove error and unknown values and set to null

*/

update dbo.dirty_cafe_sales$ 

set item = null, [payment method] = null, [location] = null

where item like 'error' or item like 'unknown' 
or [payment method] like 'error' or [payment method] like 'unknown'
or [location] like 'error' or [location] like 'unknown';


select * from dbo.dirty_cafe_sales$ 

where item like 'error' or item like 'unknown' 
or [payment method] like 'error' or [payment method] like 'unknown'
or [location] like 'error' or [location] like 'unknown';



/**

create new column that accepts new date format and use that


*/

alter table dbo.dirty_cafe_sales$ add TransactionDateConverted date;

update dbo.dirty_cafe_sales$ set [transaction date] = convert(Date, [transaction date]);

update dbo.dirty_cafe_sales$ set TransactionDateConverted = convert(Date, [transaction date]);

/**

check for similar types of entries that have different spacing or case sensitive


*/


select item, [payment method], [location] from dbo.dirty_cafe_sales$  group by item, [payment method], [location] order by item, [payment method], [location];

select [payment method], [location] from dbo.dirty_cafe_sales$ group by [payment method], [location] order by [payment method], [location];





select distinct item from dbo.dirty_cafe_sales$;

select distinct [payment method] from dbo.dirty_cafe_sales$;

select distinct [location] from dbo.dirty_cafe_sales$;

/**

fill in the missing price per unit costs and item values

check if location or payment method affects the price of the item

**/

select item, [price per unit], [payment method], [location] from dbo.dirty_cafe_sales$ 
where [price per unit] is not null and [location] is not null and [payment method] is not null and item is not null
group by item, [price per unit], [payment method], [location] order by [price per unit], [payment method], [location];

/**

we now know the CONSTANT pricing for each item and can set the null values

Cookie		$1
Tea			$1.5
Coffee		$2
Cake		$3
Juice		$3
Sandwich	$4
Smoothie	$4
Salad		$5


**/

update dbo.dirty_cafe_sales$ set [price per unit] = 1 where item like  'cookie' and [price per unit] is null;

update dbo.dirty_cafe_sales$ set [price per unit] = 1.5 where item like  'tea' and [price per unit] is null;

update dbo.dirty_cafe_sales$ set [price per unit] = 2 where item like  'coffee' and [price per unit] is null;

update dbo.dirty_cafe_sales$ set [price per unit] = 3 where item like  'juice' or item like 'cake' and [price per unit] is null;

update dbo.dirty_cafe_sales$ set [price per unit] = 4 where item like  'sandwich' or item like 'smoothie' and [price per unit] is null;

update dbo.dirty_cafe_sales$ set [price per unit] = 5 where item like  'salad' and [price per unit] is null;

/**

calculate the rest of the missing price per units using total spent and quantity

**/

update dbo.dirty_cafe_sales$ set [price per unit] = [total spent] / quantity where [price per unit] is null and quantity is not null and [total spent] is not null;

/**

fill in the missing item values using price per unit

**/
update dbo.dirty_cafe_sales$ set item = 'Cookie' where [price per unit] = 1 and item is null;

update dbo.dirty_cafe_sales$ set item = 'Tea' where [price per unit] = 1.5 and item is null;

update dbo.dirty_cafe_sales$ set item = 'Coffee' where [price per unit] = 2 and item is null;

update dbo.dirty_cafe_sales$ set item = 'Salad' where [price per unit] = 5 and item is null;




/**

calculate the missing total spent costs

**/

select * from dbo.dirty_cafe_sales$ where [total spent] is null and quantity is not null and [price per unit] is not null;

update dbo.dirty_cafe_sales$ set [total spent] = quantity * [price per unit] where [total spent] is null;

/**

calculate the missing quantity costs

**/

select * from dbo.dirty_cafe_sales$ where quantity is null;

update dbo.dirty_cafe_sales$ set quantity = [total spent] / [price per unit] where quantity is null and [price per unit] is not null and [total spent] is not null;


/*

check for incorrect total spent costs

*/

select * from dbo.dirty_cafe_sales$ where quantity * [price per unit] != [total spent];



select * from dbo.dirty_cafe_sales$;

