



/*now that our data is cleaned let's look at ways we can fix the issue of similar job titles that need to be categorized as the same job title*/
/*the occ_code is how we can organize and categorize our data, but unforunately over the past years of data the occ_codes have changed and are missing for several titles in our dataset*/
/*we lost some occ_codes when appending the data, but it doesn't matter anyway because there is some older datasets from years between 2000-2011 that need to be converted to new occ_codes anyway */
/*we need to get the new occ_code for each occ_title so that we can easily categorize our data */
/*we can take a look at the US bureau of labor statistics website and we find their list of job titles with the new occ_codes, 
those are the ones we want https://www.bls.gov/oes/current/oes_stru.htm */

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*we copy and paste all occupations into excel and import into SQL so now we have the occ_code and the occupation, 
we notice each occupation has a broad cateogory above each occupation name, let's assign levels to each category*/
--but also want to not select duplicate occ_job_titles that have different levels so let's only select the ones that are at the deepest level
create table #leveled_occupations (occ_code_id varchar(250), occ_job_title varchar(250), occ_job_category_level int );
--		drop table #leveled_occupations
insert into #leveled_occupations
select occ_code_id, occ_job_title, occ_job_category_level from (
select distinct *,case
when substring(occ_code_id, 7, 1) not like '0' then 4
when substring(occ_code_id, 7, 1) like '0' and substring(occ_code_id, 6, 1) not like '0' then 3
when substring(occ_code_id, 6, 2) like '00' and substring(occ_code_id, 4, 1) not like '0' then 2
when substring(occ_code_id, 4, 4) like '0000' then 1
end as occ_job_category_level, dense_rank() over (partition by occ_job_title order by occ_job_title, occ_code_id desc) as duplicate_rank
from occ_codes$ ) get_occ_codes
where duplicate_rank = 1 ;
/*now we have 1,166 distinct job occupations with their own unique occ_code*/ 
select distinct occ_job_title from #leveled_occupations; select * from #leveled_occupations order by occ_job_title, occ_job_category_level;
--____________________________________________________________________________________________________________________________________________________________________________________________

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*now let's get our distinct titles from our final data set*/
create table #distinctOcctitles (occ_title_id int, occ_title varchar(250) );
--		drop table #distinctOccTitles
insert into #distinctOcctitles
select distinct occ_title_id, occ_title from occ_data_final where year > 1999;    /*now we have 1,392 unique titles from our final data set*/
--____________________________________________________________________________________________________________________________________________________________________________________________

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--now let's write our join query to join occ_job_titles to occ_titles in our data based on how many words match so we can assign occ_codes
--let's store it into a table so we can process more easily after the join
create table #joined_occ_codes (occ_title_id varchar(250),	occ_code_id	varchar(250), occ_title varchar(250), occ_job_title varchar(250),	
word_match_count int, matched_words varchar(250), occ_job_category_level int, occ_title_word_count int, occ_job_title_word_count int, word_rank int);
--		drop table #joined_occ_codes
/*join on word table*/
WITH distinct_occupation_titles AS (
    SELECT occ_title_id, removed_string_occ_title, len(removed_string_occ_title) - len(REPLACE(removed_string_occ_title, ' ', '')) + 1 AS occ_title_word_count, value AS word from 

(select replace(occ_title, ',', '') as removed_string_occ_title, occ_title_id from #distinctOcctitles) removed_string_junctions

    CROSS APPLY STRING_SPLIT(removed_string_occ_title, ' ')
),
leveled_occupation_titles AS (
    SELECT occ_code_id, removed_string_occ_job_title, len(removed_string_occ_job_title) - len(REPLACE(removed_string_occ_job_title, ' ', '')) + 1 AS occ_job_title_word_count, 
	occ_job_category_level, value AS word from 

(select replace(occ_job_title, ',', '') as  removed_string_occ_job_title, occ_code_id, occ_job_category_level from #leveled_occupations) removed_string_junctions

    CROSS APPLY STRING_SPLIT(removed_string_occ_job_title, ' ')
),
MatchedWords AS (
    SELECT occ_title_id, occ_code_id,
        removed_string_occ_title, 
        removed_string_occ_job_title,  
        COUNT(DISTINCT lot.word) AS word_match_count,-- Counts how many words were used in the join

		(SELECT STRING_AGG(word, ' ') 
            FROM (SELECT DISTINCT lot2.word 
                  FROM leveled_occupation_titles lot2
                  JOIN distinct_occupation_titles dot2 
                      ON lot2.word = dot2.word 
                  WHERE dot2.occ_title_id = dot.occ_title_id 
                    AND lot2.occ_code_id = lot.occ_code_id) AS unique_words) AS matched_words, --gives us the words that are used to used in the join
		 occ_job_category_level,
		occ_title_word_count, occ_job_title_word_count
	
    FROM distinct_occupation_titles dot
     join leveled_occupation_titles lot
        ON dot.word = lot.word  -- Join when words match
    GROUP BY removed_string_occ_title, occ_title_id, occ_title_word_count, removed_string_occ_job_title, occ_code_id, occ_job_category_level, occ_job_title_word_count
)
insert into #joined_occ_codes
SELECT *, dense_rank() over (partition by removed_string_occ_title order by word_match_count desc) as word_rank
FROM MatchedWords
WHERE word_match_count BETWEEN 1 AND 30  -- Filter for at least 1 to 30 matching words
ORDER BY removed_string_occ_title asc, word_match_count desc, occ_job_category_level desc;
--____________________________________________________________________________________________________________________________________________________________________________________________

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*let's grab our distinct title's that have a perfect match and store them somewhere*/
create table #perfect_match_occ_title_codes (occ_title_id int, occ_code_id varchar(7), occ_title varchar(250), occ_job_title varchar(250) );
--		drop table #perfect_match_occ_title_codes
insert into #perfect_match_occ_title_codes
select occ_title_id, occ_code_id, occ_title, occ_job_title from 
(select occ_title_id, occ_code_id, occ_title, occ_job_title, DENSE_RANK() over (partition by occ_title order by occ_job_category_level desc) as level_ranked 
from #joined_occ_codes where word_rank = 1 and occ_title like occ_job_title) ranked_level
where level_ranked = 1
order by occ_title;
/*1,134 rows joined successfully*/ select distinct occ_title_id from #perfect_match_occ_title_codes; --make sure we have just one occ_code assigned for each one occ_title_id
--____________________________________________________________________________________________________________________________________________________________________________________________

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
create table #other_joined_occ_title_codes (occ_title_id int, occ_code_id varchar(7), occ_title varchar(250), occ_job_title varchar(250) );
--			drop table #other_joined_occ_title_codes
insert into #other_joined_occ_title_codes
select occ_title_id, occ_code_id, occ_title, occ_job_title from (
select *, row_number() over (partition by occ_title order by word_count_diff, occ_job_category_level) as parted_rows_rank from (
select *, abs(word_match_count - occ_job_title_word_count) as word_count_diff, count(occ_title) over (partition by occ_title ) as tie_matches ,
dense_rank() over (partition by occ_title order by word_rank, occ_job_category_level) as category_rank
from #joined_occ_codes where
 trim(matched_words) not like 'and' 
 and trim(matched_words) not like 'all other' and trim(matched_words) not like 'all and other'
 and trim(matched_words) not like 'and other' and trim(matched_words) not like 'other' and trim(matched_words) not like 'and other workers' and trim(matched_words) not like 'all other workers'
 and trim(matched_words) not like 'and related workers' and trim(matched_words) not like 'all and other workers' and trim(matched_words) not like 'all and other related workers'
 and trim(matched_words) not like 'and engineers'
 and occ_title not like '%supervisor%' and occ_job_title not like '%supervisor%'
 and occ_title not like '%all other%' and occ_job_title not like '%except%' and occ_job_title not like '%manager%' and occ_title not like '%manager%'
 and occ_title not in (select occ_title from #perfect_match_occ_title_codes )
 and word_match_count > 1
 and word_rank = 1 ) rankInitial
 where tie_matches < 6) grab_just_first_rows
 where parted_rows_rank = 1;
--____________________________________________________________________________________________________________________________________________________________________________________________


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* we will execute this query and then export to excel to manually assign correct job codes for these and then import back as table */
select occ_title_id, 'codes' + occ_code_id as occ_code_id /*had to put codes in because excel kept automatically convert some to date*/, occ_title, occ_job_title, word_match_count, matched_words, occ_job_category_level, occ_title_word_count, occ_job_title_word_count, word_rank, abs(word_match_count - occ_job_title_word_count) as word_count_diff, count(occ_title) over (partition by occ_title ) as tie_matches ,
dense_rank() over (partition by occ_title order by word_rank, occ_job_category_level) as category_rank
from #joined_occ_codes where
 trim(matched_words) not like 'and' 
 and trim(matched_words) not like 'all other'  and trim(matched_words) not like 'all and other'
 and trim(matched_words) not like 'and other'  and trim(matched_words) not like 'other' and trim(matched_words) not like 'and other workers'
 and trim(matched_words) not like 'all other workers' and trim(matched_words) not like 'and related workers' 
 and trim(matched_words) not like 'all and other workers' and trim(matched_words) not like 'all and other related workers'
 and occ_title not in (select occ_title from #perfect_match_occ_title_codes ) and occ_title not in (select occ_title from #other_joined_occ_title_codes )
 and word_match_count > 1
 and word_rank =  1
 order by tie_matches, occ_title, word_rank, word_count_diff, occ_job_category_level;
 --____________________________________________________________________________________________________________________________________________________________________________________________

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*check to see how much data we still don't have occ_codes for */
select * from occ_data_final where occ_title_id not in (select occ_title_id from #perfect_match_occ_title_codes) and occ_title_id not in (select occ_title_id from #other_joined_occ_title_codes) 
and occ_title_id not in (select occ_title_id from final_other_joined_occ_title_codes) and year > 1999; /*now only 463 rows so we just won't use those in our dataset final*/
--____________________________________________________________________________________________________________________________________________________________________________________________


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*let's union all our occ_code titles */
create table #unioned_occ_title_codes (occ_title_id int,  occ_code_id varchar(250), occ_title varchar(250), occ_job_title varchar(250) );
--		drop table #unioned_occ_title_codes

insert into #unioned_occ_title_codes
select * from #perfect_match_occ_title_codes union all select * from #other_joined_occ_title_codes union all select * from final_other_joined_occ_title_codes ;

--check rows that have those names
select * from occ_data_final where occ_title_id in (select occ_title_id from #unioned_occ_title_codes) and year > 1999;--25,497
--____________________________________________________________________________________________________________________________________________________________________________________________



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*assinging our categories for use in tableau dashboard*/

select occ_title_id, occ_code, occ_job_title, h_mean, a_mean, year, job_category1, case when job_category3 is null then occ_job_title else job_category3 end as job_category3 from (

select occ_title_id, occ_code, fdsj.occ_job_title, h_mean, a_mean, year, lvl1codes.occ_job_title as job_category1, lvl3codes.occ_job_title as job_category3 from final_data_set_join fdsj

left join ( select distinct * from occ_codes$ where substring(occ_code_id, 4, 4) like '0000' ) lvl1codes on substring(occ_code, 6, 2) = substring(lvl1codes.occ_code_id, 1, 2)

left join ( select distinct * from occ_codes$ where substring(occ_code_id, 7, 1) like '0' and substring(occ_code_id, 6, 1) not like '0' ) lvl3codes on substring(occ_code, 6, 6) = substring(lvl3codes.occ_code_id, 1, 6)
) assign_category_query

--____________________________________________________________________________________________________________________________________________________________________________________________



