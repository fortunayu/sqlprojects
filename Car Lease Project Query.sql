use datahub 
---Data Prep: update the wrong spelling name of each salesperson in the 'dealer' table
update dealer
set salesperson='JimVogler'
where salesperson like 'Jim %'

update dealer
set salesperson='MansurNaser'
where salesperson like 'Man%'

update dealer
set salesperson='NoraPalermo'
where salesperson like 'Nora%'

update dealer
set salesperson='RachelArellano'
where salesperson like 'Rach%'

update dealer
set salesperson='SaminGupta'
where salesperson like 'S%'


-- Q1. A monthly trending of the average revenue brought in by approved applications submitted by each salesperson's dealer base 
-- use Pivot table
with cte5 as (select d.salesperson,   --combine the tables and get the latest submission date with approved revenue
       s.submission_date,
	   s.revenue,
	   s.application_id,
	   s.submission_id,
	   max(s.submission_date)over( partition by a.application_id ) as latest_subdate
from dealer as d
join application as a
on d.dealer_key = a.dealer_key
join submission_history as s
on a.application_id=s.application_id
where a.status='Approved'),
maxdate as (select salesperson,
       submission_date,
	   submission_id,
	   application_id,
	   revenue
from cte5 
where submission_date=latest_subdate),
maxid as (select  salesperson,  -- get the max submission ID for the same date
       submission_date,
	   submission_id,
	   application_id,
	   revenue,
       max(submission_id) over ( partition by application_id ) as max_subid
from maxdate)

select * from (select salesperson,  -- pivot the table
       month(submission_date) as sub_month,
	   revenue
from maxid
where submission_id=max_subid
) as approvedrevbymonth
pivot(
    AVG(revenue)
	for salesperson
	in (JimVogler,MansurNaser,NoraPalermo,RachelArellano, SaminGupta)
		) as PivotTable
order by sub_month


-- The profitability of applications originating from each salesperson's dealer base
with cte as(
select distinct d.salesperson,
	   sum(s.revenue) as subtotalrev,
	   sum(case when status='Approved' then revenue end) as approvedrev,
	   sum(case when status='Rejected' then revenue end) as rejedrev
from dealer as d
left join application as a
on d.dealer_key = a.dealer_key
left join submission_history as s
on a.application_id=s.application_id
group by d.salesperson)

select salesperson,
       subtotalrev,
	   approvedrev,
	   rejedrev,
	   sum(subtotalrev)over(partition by salesperson)*100/(select sum(subtotalrev) from cte) as pct
from cte
order by subtotalrev desc

--Number of submission & sales amount per submission per salesperson
with cte1 as(
select d.salesperson,
       s.submission_id,
	   a.status,
	   s.revenue
from dealer as d
left join application as a
on d.dealer_key = a.dealer_key
left join submission_history as s
on a.application_id=s.application_id)

select distinct salesperson,
                sum(revenue) as sub_totalrev,
				count(submission_id) as sub_totalsub,
				sum(revenue)/count(submission_id)as amount_per_sub
from cte1
group by salesperson
order by amount_per_sub desc




--Q2.Find the percentage of dealers in each salesperson's dealer base that are "consistently active"
--A dealer that has submitted three or more applications in each of the preceding three calendar months is labeled as a "consistently active" dealer

--step 1: create a consistently active list based on the definition by screening the the latest submission time and max submission ID for the same application with the same submission date
--step 2: Find the percentage of dealers in each salesperson's dealer base by joining the consistently active list with each salesperson's dealer base

--Step1
--create consistently active list
with cte6 as (select d.DealerName,
       s.submission_date,
       s.submission_id,
	   s.application_id,
	   max(s.submission_date)over( partition by a.application_id ) as latest_subdate
from dealer as d
join application as a
on d.dealer_key = a.dealer_key
join submission_history as s
on a.application_id=s.application_id
where month(s.submission_date) in (5,6,7)),
maxdate1 as (select dealername,
       submission_date,
	   submission_id,
	   application_id,
	   latest_subdate
from cte6
where submission_date=latest_subdate),
maxid1 as (select dealername,  -- get the max submission ID for the same date
       submission_date,
	   month(submission_date) as sub_month,
	   submission_id,
	   application_id,
       max(submission_id) over ( partition by application_id ) as max_subid
from maxdate1)
select dealername,  
       sub_month,
	   count(submission_id) as count_sub
from maxid1
where submission_id=max_subid
group by dealername,sub_month
having count(submission_id)>=3
order by DealerName;

select* from consistently_active_list

--Step 2
 --Jim Vogler's base-pct-consistently active
with cte3 as (
 select dealername,
       count(dealername) as count_name
from consistently_active_list
group by dealername
having count(dealername)=3),
jimactive as (
 select cte3.dealername,
       d.salesperson
from cte3 
left join dealer as d
on d.DealerName=cte3.dealername
where salesperson='JimVogler'),
jimbase as(select d.dealername
from dealer as d
where salesperson='JimVogler'),
jimfull as (select jimbase.dealername as jim_base,
       jimactive.dealername as jim_active
from jimbase 
full join jimactive
on jimbase.DealerName=jimactive.dealername)

select count(jim_active) as jim_active,
       count(*) as jim_base ,
       cast(count(jim_active) as numeric(5,2))/ count(*)as pct_Jim_active
from jimfull

--Mansur Naser's base-pct-consistently active
with cte3 as (
 select dealername,
       count(dealername) as count_name
from consistently_active_list
group by dealername
having count(dealername)=3),
Manactive as (
 select cte3.dealername,
       d.salesperson
from cte3 
left join dealer as d
on d.DealerName=cte3.dealername
where salesperson='MansurNaser'),
Manbase as(select d.dealername 
from dealer as d
where salesperson='MansurNaser'),
Manfull as (select manbase.dealername as man_base,
       manactive.dealername as man_active
from manbase 
full join manactive
on manbase.DealerName=manactive.dealername)

select count(man_active) as man_active,
       count(*) as man_base ,
       cast(count(man_active) as numeric(5,2))/ count(*) as pct_Mansur_active
from Manfull


--Nora Palermo's base-pct-consistently active
with cte3 as (
 select dealername,
       count(dealername) as count_name
from consistently_active_list
group by dealername
having count(dealername)=3),
noraactive as (
 select cte3.dealername,
       d.salesperson
from cte3 
left join dealer as d
on d.DealerName=cte3.dealername
where salesperson='NoraPalermo'),
norabase as(select d.dealername
from dealer as d
where salesperson='NoraPalermo'),
norafull as (select norabase.dealername as nora_base,
       noraactive.dealername as nora_active
from norabase 
full join noraactive
on norabase.DealerName=noraactive.dealername)
select count(nora_active) as nora_active,
       count(*) as nora_base ,
       cast(count(nora_active) as numeric(5,2))/count(*) as pct_nora_active
from norafull


--Rachel Arellano's base-pct-consistently active
with cte3 as (
 select dealername,
       count(dealername) as count_name
from consistently_active_list
group by dealername
having count(dealername)=3),
racactive as (
 select cte3.dealername,
       d.salesperson
from cte3 
left join dealer as d
on d.DealerName=cte3.dealername
where salesperson='RachelArellano'),
racbase as(select d.dealername
from dealer as d
where salesperson='RachelArellano'),
racfull as (select racbase.dealername as rac_base,
       racactive.dealername as rac_active
from racbase 
full join racactive
on racbase.DealerName=racactive.dealername)

select count(rac_active) as rac_active,
       count(*) as rac_base ,
       cast(count(rac_active) as numeric(5,2)) / count(*) as pct_Rachel_active
from racfull

--Samin Gupta's base-pct-consistently active
with cte3 as (
 select dealername,
       count(dealername) as count_name
from consistently_active_list
group by dealername
having count(dealername)=3),
samactive as (
 select cte3.dealername,
       d.salesperson
from cte3 
left join dealer as d
on d.DealerName=cte3.dealername
where salesperson='SaminGupta'),
sambase as(select d.dealername
from dealer as d
where salesperson='SaminGupta'),
samfull as (select sambase.dealername as sam_base,
       samactive.dealername as sam_active
from sambase 
full join samactive
on sambase.DealerName=samactive.dealername)

select count(sam_active) as sam_active,
       count(*) as sam_base ,
       cast(count(sam_active) as numeric(5,2))/ count(*) as pct_Samin_active
from samfull

--Q3. A list of dealers that should be visited by the salespersons this month to follow-up on their drop in submission activity
--A dealer that has submitted five or more applications in each of the first two of the preceding three calendar months 
--but less than three applications in most recent one should be flagged for in-person visit

--step 1: Find an in person visit list based on the definition 
--step 2: Find the salesperson who needs to do the in person visit by August

--step 1
--Find an in person visit list based on the definition 
with cte6 as (select d.DealerName,
       s.submission_date,
       s.submission_id,
	   s.application_id,
	   max(s.submission_date)over( partition by a.application_id ) as latest_subdate
from dealer as d
join application as a
on d.dealer_key = a.dealer_key
join submission_history as s
on a.application_id=s.application_id
where month(s.submission_date) in (5,6,7)),
maxdate1 as (select dealername,
       submission_date,
	   submission_id,
	   application_id,
	   latest_subdate
from cte6
where submission_date=latest_subdate),
maxid1 as (select dealername,  -- get the max submission ID for the same date
       submission_date,
	   month(submission_date) as sub_month,
	   submission_id,
	   application_id,
       max(submission_id) over ( partition by application_id ) as max_subid
from maxdate1),
inpersonvisit as( select DealerName,
       sub_month,
	  count(submission_id) as count_sub
from maxid1
where submission_id=max_subid
group by dealername,sub_month
having sub_month=5 and count(submission_id) >=5
or sub_month=6 and count(submission_id) >=5
or sub_month=7 and count(submission_id)<=3)

select dealername,
       count(dealername) as count_name
from inpersonvisit
group by dealername
having count(dealername)=3

--step 2: 
--Find the salesperson who needs to do in person visit dealer
select dealername,
       salesperson
from dealer as d
where dealername='Dynamic Ink Design'







