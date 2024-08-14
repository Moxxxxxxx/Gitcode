#!/bin/bash

# --------------------------------------------------------------------------------------------------
#-- 运行类型 ： 日跑
#-- 参数 ：     d 
#-- 功能描述 ： 项目 dwd层  盘点单状态变化信息
#-- 注意 ： 每日按天增量分区,每天的分区即为当天的分区数据
#-- 输入表 : ods.ods_qkt_cyclecount_cycle_count_state_change_da
#-- 输出表 ：dwd.dwd_cyclecount_cycle_count_state_change_info_da
#-- 修改历史 ： 修改人 修改时间 主要改动说明
#-- 1 wangziming 2022-03-01 CREATE 

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



insert overwrite table ${dwd_dbname}.dwd_cyclecount_cycle_count_state_change_info_da partition(d,pt)
select 
id,
warehouse_id,
cycle_count_id,
state as cyclecount_state,
remark,
created_date as cyclecount_created_time,
created_user as cyclecount_created_user,
created_app as cyclecount_created_app,
last_updated_date as  cyclecount_updated_time,
last_updated_user as  cyclecount_updated_user,
last_updated_app as cyclecount_updated_app,
project_code,
d,
project_code as pt
from 
${ods_dbname}.ods_qkt_cyclecount_cycle_count_state_change_da 
;
"
sql="
set hive.execution.engine=mr;
set mapreduce.job.queuename=hive;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
set hive.exec.max.dynamic.partitions=1000;
set hive.exec.max.dynamic.partitions.pernode=500;


insert overwrite table ${dwd_dbname}.dwd_cyclecount_cycle_count_state_change_info_da partition(d='${pre1_date}',pt)
select 
id,
warehouse_id,
cycle_count_id,
state as cyclecount_state,
remark,
created_date as cyclecount_created_time,
created_user as cyclecount_created_user,
created_app as cyclecount_created_app,
last_updated_date as  cyclecount_updated_time,
last_updated_user as  cyclecount_updated_user,
last_updated_app as cyclecount_updated_app,
project_code,
project_code as pt
from 
${ods_dbname}.ods_qkt_cyclecount_cycle_count_state_change_da
where d='${pre1_date}'
;
"


printf "##############################################start-executor-sql####################################################################\n$sql\n##############################################end-executor-sql####################################################################"

$hive -e "$sql"
