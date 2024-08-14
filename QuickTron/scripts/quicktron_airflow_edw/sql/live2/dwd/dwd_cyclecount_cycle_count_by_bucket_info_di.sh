#!/bin/bash
# --------------------------------------------------------------------------------------------------
#-- 运行类型 ： 日跑
#-- 参数 ：     d 
#-- 功能描述 ： 项目 dwd层   货架盘点
#-- 注意 ： 每日按天增量分区
#-- 输入表 : ods.ods_qkt_cyclecount_cycle_count_by_bucket_di
#-- 输出表 ：dwd.dwd_cyclecount_cycle_count_by_bucket_info_di
#-- 修改历史 ： 修改人 修改时间 主要改动说明
#-- 1 wangziming 2022-02-28 CREATE 

# ------------------------------------------------------------------------------------------------

ods_dbname=ods
dwd_dbname=dwd
hive=/opt/module/hive-3.1.2/bin/hive


# 如果是输入的日期按照取输入日期；如果没输入日期取当前时间的前一天
if [ -n "$1" ] ;then
    pre1_date=$1
else 
    pre1_date=`date -d "-1 day" +%F`
fi

if [ -n "$1" ] ;then
    pre2_date=`date -d "-1 day $1" +%F`
else
    pre2_date=`date -d "-2 day" +%F`
fi

echo "##############################################hive:{start executor dwd}####################################################################"



init_sql="
set hive.execution.engine=mr;
set mapreduce.job.queuename=hive;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
set hive.exec.max.dynamic.partitions=1000;
set hive.exec.max.dynamic.partitions.pernode=500;



insert overwrite table ${dwd_dbname}.dwd_cyclecount_cycle_count_by_bucket_info_di partition(d,pt)
select 
id,
warehouse_id,
cycle_count_id,
bucket_code,
bucket_face,
bucket_slot_code,
delete_flag,
created_date as bucket_created_time,
created_user as bucket_created_user,
created_app as bucket_created_app,
last_updated_date as bucket_updated_time,
last_updated_user as bucket_updated_user,
last_updated_app as bucket_updated_app,
project_code,
substr(created_date,0,10) as d,
project_code as pt
from 
 ( 
select 
*
,row_number() over(partition by id,project_code order by last_updated_date desc ) as rn 
from
${ods_dbname}.ods_qkt_cyclecount_cycle_count_by_bucket_di 
) t
where t.rn=1

;
"
sql="
set hive.execution.engine=mr;
set mapreduce.job.queuename=hive;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
set hive.exec.max.dynamic.partitions=1000;
set hive.exec.max.dynamic.partitions.pernode=500;


with tmp_cycle_count_by_bucke_str1 as (
select 
distinct substr(created_date,0,10) as d,project_code
from
${ods_dbname}.ods_qkt_cyclecount_cycle_count_by_bucket_di
where d='${pre1_date}' and substr(created_date,0,10)<>'${pre1_date}'
),
tmp_cycle_count_by_bucke_str2 as (
select 
*
from 
${dwd_dbname}.dwd_cyclecount_cycle_count_by_bucket_info_di
where d in (select distinct d from tmp_cycle_count_by_bucke_str1) 
and pt in (select distinct project_code from tmp_cycle_count_by_bucke_str1)
)
insert overwrite table dwd.dwd_cyclecount_cycle_count_by_bucket_info_di partition(d,pt)
select 
id,
warehouse_id,
cycle_count_id,
bucket_code,
bucket_face,
bucket_slot_code,
delete_flag,
bucket_created_time,
bucket_created_user,
bucket_created_app,
bucket_updated_time,
bucket_updated_user,
bucket_updated_app,
project_code,
d,
project_code as pt
from 
(
select 
*,
row_number() over(partition by id,project_code order by bucket_updated_time desc) as rn
from 
(
select 
id,
warehouse_id,
cycle_count_id,
bucket_code,
bucket_face,
bucket_slot_code,
delete_flag,
created_date as bucket_created_time,
created_user as bucket_created_user,
created_app as bucket_created_app,
last_updated_date as bucket_updated_time,
last_updated_user as bucket_updated_user,
last_updated_app as bucket_updated_app,
project_code,
substr(created_date,0,10) as d
from 
${ods_dbname}.ods_qkt_cyclecount_cycle_count_by_bucket_di
where d='${pre1_date}'

union all
select 
id,
warehouse_id,
cycle_count_id,
bucket_code,
bucket_face,
bucket_slot_code,
delete_flag,
bucket_created_time,
bucket_created_user,
bucket_created_app,
bucket_updated_time,
bucket_updated_user,
bucket_updated_app,
project_code,
d
from 
tmp_cycle_count_by_bucke_str2
) t
) rt 
where rt.rn=1
;
"


printf "##############################################start-executor-sql####################################################################\n$sql\n##############################################end-executor-sql####################################################################"

$hive -e "$sql"


