
/*gpu product comparison project */

/*let's take a look at the product data and clean this data */
select * from neweggGPUDataUpdatedURL; 
/*let's remove that first row that is null*/
delete from neweggGPUDataUpdatedURL where Description like 'null' and brand is null and currentprice is null and 
PreviousPrice is null and reviews is null and Availability like 'null' and URL like 'null';

/*check for duplicate rows in the data*/

/*from the results of this query it looks the only time we have duplicate items with the same Description, CurrentPrice is out of stock items*/
with cte_groups as ( select *, count(description) over(partition by description, currentprice order by description) as descriptCount from neweggGPUDataUpdatedURL )
select * from neweggGPUDataUpdatedURL where Description in ( select description from cte_groups where descriptCount > 1) order by Description;

/*let's now check for duplicate rows for items in stock with just the same Description*/
with cte_groups as ( select *, count(description) over(partition by description order by description) as descriptCount from neweggGPUDataUpdatedURL where Availability not like 'out of stock' )
select * from neweggGPUDataUpdatedURL where Description in ( select description from cte_groups where descriptCount > 1) order by Description;
/*it looks like we have some rows that have the same Description but other columns such as CurrentPrice is different, let's ignore these duplicates for now*/

/* it looks like something wierd happen with the import data and it created 2 extra columns, only 2 records were affected so we will just delete those records and remove the columns */
select * from neweggGPUDataUpdatedURL where f8 is not null or f9 is not null;

delete from neweggGPUDataUpdatedURL where f8 is not null;

alter table neweggGPUDataUpdatedURL drop column f8;

alter table neweggGPUDataUpdatedURL drop column f9;

/*let's fix the reviews that imported incorrectly from excel*/
select cast(substring(cast(reviews as varchar), 2, 100) as int) from neweggGPUDataUpdatedURL where reviews is not null;
/*removes the negative sign*/
update neweggGPUDataUpdatedURL set reviews = cast(substring(cast(reviews as varchar), 2, 100) as int) where reviews is not null;
/*changes the null reviews to be 0 instead of null*/
update neweggGPUDataUpdatedURL set reviews = 0 where reviews is null;

/*some values are string nulls instead of actual nulls so let's fix that*/
select PreviousPrice from neweggGPUDataUpdatedUrl where previousprice like 'null';
update neweggGPUDataUpdatedURL set PreviousPrice = null where PreviousPrice like 'null';
select brand from neweggGPUDataUpdatedURL where brand like 'null';
update neweggGPUDataUpdatedURL set brand = null where brand like 'null';

/*now let's fix the previous price*/
/*remove $ from previousprice*/
select previousprice from neweggGPUDataUpdatedURL;

select substring(previousPrice, 2, 100) from neweggGPUDataUpdatedUrl where previousPrice is not null;
update neweggGPUDataUpdatedURL set PreviousPrice = substring(previousPrice, 2, 100) where PreviousPrice is not null;

/*remove , from previousPrice*/
select replace(previousPrice, ',', '') from neweggGPUDataUpdatedURL where PreviousPrice is not null;
update neweggGPUDataUpdatedURL set PreviousPrice = replace(previousPrice, ',', '') where PreviousPrice is not null;

/*convert previousprice to float*/
alter table neweggGPUDataUpdatedURL alter column previousPrice float;

/* some items say limited time offer instead of in stock, this means the product is still in stock so let's change to IN STOCK instead */
select availability from neweggGPUDataUpdatedURL where Availability not like 'out of stock' and Availability not like 'in stock';
update neweggGPUDataUpdatedURL set Availability = 'IN STOCK' where Availability not like 'out of stock' and Availability not like 'in stock';


/*now we want to join the benchmarkGPUData table where the video card name matches the description in the neweggGPUDataUpdateURL table */

/*create temp table for storing this joined query*/
create table #joinedBenchmarkProduct (
gpu_descr varchar(255), gpu_name varchar(255), 
g3dm float, g2dm float, tdpw nvarchar(255), brand varchar(255), cprice float, prevprice float, stock varchar(255), reviews varchar(255), purl varchar(255) )
;

/*use this to reset our temp table values after we adjusted our join query in testing*/
drop table #joinedBenchmarkProduct;

/* next we insert our left join query into this temp table so we can run the join query faster and filter out results
here we are joining the benchmark data to the table with all the newegg products in it so we can see the benchmark for each product on newegg
we also make sure to filter the out of stock items because those are not really relevant since newegg keeps old out of stock items on their site, that will never likely be restocked in the future
*/
insert into #joinedBenchmarkProduct
select Description, [Video Card Name],[G3D Mark], [G2D Mark], [TDP (W) ], brand, CurrentPrice, PreviousPrice, Availability, Reviews, URL from neweggGPUDataUpdatedURL left join benchmarkGPUData 
on replace(description, ' ', '') like '%' + replace([video card name], ' ', '') + '%'
where [Video Card Name] is not null and Availability not like 'out of stock'
;


select * from #joinedBenchmarkProduct order by gpu_descr, gpu_name;
/*we select from the join query and find it gives us extra results that we don't need, this is because some graphics cards have the same name but then extra editions at the end such as below
Used - Very Good GIGABYTE GeForce GTX 1050 OC Low Profile 2GB Video Card, GBTGV-N1050OC-2GL												GeForce GTX 1050
Used - Very Good GIGABYTE GeForce GTX 1050 Ti 4GB GDDR5 PCI Express 3.0 x16 ATX Video Card GV-N105TWF2OC-4GD							GeForce GTX 1050
Used - Very Good GIGABYTE GeForce GTX 1050 Ti 4GB GDDR5 PCI Express 3.0 x16 Low Profile Video Card GV-N105TOC-4GL						GeForce GTX 1050
Used - Very Good MSI GeForce GTX 1050 2GB GDDR5 PCI Express 3.0 x16 ATX Video Card GTX 1050 2G OC										GeForce GTX 1050
Yeston GeForce GTX 1050 Ti 4GB GDDR5 Graphics cards pci express x16 3.0 video cards Desktop computer PC video gaming graphics card		GeForce GTX 1050
Yeston GeForce GTX 1050 Ti 4GB GDDR5 LP Graphics cards pci express 3.0 video cards Desktop computer PC video gaming graphics card		GeForce GTX 1050
ASUS Cerberus GeForce GTX 1050 Ti 4GB OC Edition GDDR5 Gaming Graphics Card, CERBERUS-GTX1050TI-O4G										GeForce GTX 1050 Ti
GIGABYTE GeForce GTX 1050 Ti 4GB GDDR5 PCI Express 3.0 x16 ATX Video Cards GV-N105TD5-4GD												GeForce GTX 1050 Ti

as you can see the table joined gtx 1050 benchmarks on product results that were 1050 TI, but we can filter these out from the joined query

if we order by gpu_descr which is from the neweggGPUDataUpdatedURL table and then by gpu_name which is from the benchmarkGPUData table length desc

we can just return the first value of each row so it won't give us the results that shouldn't be joined
*/


/*this query will now return the products we are looking for as well as the respective Benchmarks of that products however, there is still more filtering to do
let's look at the results of this query and see if any gpu_name still joined were we didn't want them too
*/
with rank_table as (select *, rank() over(partition by gpu_descr order by gpu_descr, len(gpu_name) desc) as GPUrank from #joinedBenchmarkProduct )
select gpu_descr, gpu_name, g3dm, g2dm, tdpw, brand, cprice, prevprice, stock, reviews, purl from rank_table where GPUrank = 1 order by gpu_name
;

/* We notice from the query above we got a gpu_name 'ION' from the benchmark table, 
this is not GPU is not in our neweggGPUDataUpdatedURL table
so let's remove that as well from our results query */
with rank_table as (select *, rank() over(partition by gpu_descr order by gpu_descr, len(gpu_name) desc) as GPUrank from #joinedBenchmarkProduct )
select gpu_descr, gpu_name, g3dm, g2dm, tdpw, brand, cprice, prevprice, stock, reviews from rank_table where GPUrank = 1 and gpu_name not like 'ion' order by gpu_name
;

/*now that we have that data let's insert into a temp table so we can further process some things before exporting it into tableau
for example we would like to see the lowest and highest price of GPU for each category
*/
create table #finalResultTableProcess ( gpu_id int, gpu_category_id int,
gpu_description varchar(255), gpu_name varchar(255), 
g3dMark float, g2dMark float, tdpw nvarchar(255), brand varchar(255), CurrentPrice float, PreviousPrice float, stock varchar(255), reviews varchar(255) )
;

/*removes table for testing*/
drop table #finalResultTableProcess;


with rank_table as (select *, rank() over(partition by gpu_descr order by gpu_descr, len(gpu_name) desc) as GPUrank, 
dense_rank() over (order by gpu_name) as gpu_category_id, 
row_number() over(order by gpu_descr) as gpu_id from #joinedBenchmarkProduct )
insert into #finalResultTableProcess
select gpu_id, gpu_category_id, gpu_descr, gpu_name, g3dm, g2dm, tdpw, brand, cprice, prevprice, stock, reviews from rank_table where GPUrank = 1 and gpu_name not like 'ion' order by gpu_name
;

select * from #finalResultTableProcess order by gpu_name;
/*query that gives us the min and max price for each gpu_category*/
select gpu_category_id, gpu_name, min(currentPrice) as LowestGPUPrice, max(CurrentPrice) as HighestGPUPrice from #finalResultTableProcess group by gpu_category_id, gpu_name;

select * from #finalResultTableProcess frtp inner join
(select gpu_category_id, gpu_name, min(currentPrice) as LowestGPUPrice, max(CurrentPrice) as HighestGPUPrice from #finalResultTableProcess group by gpu_category_id, gpu_name) MaxMinGPUPrices
on frtp.gpu_category_id = MaxMinGPUPrices.gpu_category_id
;




/*this gives us the min and max price of ID for each gpu_name and also gives us the gpu_id, however, this information is not relevant for tableau purposes*/
with cte_priceRank as(
select *, rank() over (partition by gpu_name order by currentPrice) as priceRankLow,
rank() over (partition by gpu_name order by currentPrice desc) as priceRankHigh
from #finalResultTableProcess )

select priceRankLowTable.gpu_category_id, priceRankLowTable.gpu_name, priceRankLowTable.gpu_id as LowPriceGPU_id, priceRankLowTable.currentPrice as LowestGPUPrice, 
priceRankHighTable.gpu_id as HighPriceGPU_id, priceRankHighTable.currentPrice as HighestGPUPrice
from 
(select * from cte_priceRank where priceRankLow = 1) priceRankLowTable
full outer join 
(select * from cte_priceRank where priceRankHigh = 1) priceRankHighTable
on priceRankLowTable.gpu_category_id = priceRankHighTable.gpu_category_id
order by priceRankLowTable.gpu_category_id
;