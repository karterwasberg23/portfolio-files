

select * from occ_data_final;



select lower(trim(occ_title)) from occ_data_final;

--fix occ_title 
update occ_data_final set occ_title = lower(trim(occ_title));

select replace(occ_title, '*', ' ') from occ_data_final where occ_title like '%*%';
/*remove '*' from titles*/
update occ_data_final set occ_title = replace(occ_title, '*', ' ');

/*figuring out calculation necessary to fill in values where h_mean is null*/
select occ_title, h_mean, a_mean, round((a_mean/12.0)/173.36485421, 2) as hourly_wage_calc,
abs(h_mean - round((a_mean/12.0)/173.36485421, 2) ) as abs_difference
from occ_data_final order by abs_difference desc;

/*looks like there isn't any spots where a_mean is null and h_mean isn't so we just have to get rid of those null rows*/
select * from occ_data_final where a_mean is null and h_mean is not null;

/*still have about 203 rows where h_mean and a_mean is null, let's rmove those rows from our data*/
select * from occ_data_final where h_mean is null and a_mean is null;
delete from occ_data_final where h_mean is null and a_mean is null;
--update rows to fill in h_mean calculation
update occ_data_final set h_mean = round((a_mean/12.0)/173.36485421, 2) where h_mean is null;


/*looks like occ_code is null in a lot of rows lets make our own ID for the occ_title column*/
/*add our occ_title_ID column*/
alter table occ_data_final add occ_title_ID int;
with cte_dense_rank as (select DENSE_RANK() over( order by occ_title) as occ_title_ID_num, occ_title from occ_data_final )
update occ_data_final set occ_title_ID = occ_title_ID_num from cte_dense_rank where cte_dense_rank.occ_title = occ_data_final.occ_title ;



/*double check we got our id's right*/
with cte_dense_rank as (select DENSE_RANK() over( order by occ_title) as occ_title_ID_num, occ_title_id, occ_title from occ_data_final )
select * from cte_dense_rank where occ_title_ID != occ_title_ID_num;



/*look at rows where occ_title is null*/
select * from occ_data_final where occ_title is null;
/*just one row so lets remove*/
delete from occ_data_final where occ_title is null;




select occ_title_ID, occ_title, h_mean, a_mean, year, mean_prse, h_pct10, h_pct25, h_pct75, h_pct90, a_pct10, a_pct25, a_pct75, a_pct90 from occ_data_final;




