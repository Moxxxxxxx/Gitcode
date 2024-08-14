#!/bin/bash

# --------------------------------------------------------------------------------------------------
#-- 运行类型 ： 日跑
#-- 参数 ：     d 
#-- 功能描述 ： ones项目属性选择值维度表
#-- 注意 ： 每天全量覆盖
#-- 输入表 : ods.ods_qkt_ones_project_field_df
#-- 输出表 ：dim.dim_ones_project_field_option_value_info
#-- 修改历史 ： 修改人 修改时间 主要改动说明
#-- 1 wangziming 2022-04-07 CREATED 

# ------------------------------------------------------------------------------------------------


ods_dbname=ods
dim_dbname=dim
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



sql="
set hive.execution.engine=mr;
set mapreduce.job.queuename=hive;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
set hive.exec.max.dynamic.partitions=1000;
set hive.exec.max.dynamic.partitions.pernode=500;


with tmp_project_field_option_str1 as (
select 
distinct options
from 
${ods_dbname}.ods_qkt_ones_project_field_df
where d='${pre1_date}' 
),
tmp_project_field_option_str2 as (
select 
distinct statuses
from 
${ods_dbname}.ods_qkt_ones_project_field_df
where d='${pre1_date}' 
)
insert overwrite table ${dim_dbname}.dim_ones_project_field_option_value_info
select 
get_json_object(cols,'$.uuid') as option_uuid,
get_json_object(cols,'$.value') as option_value,
'0' as is_built_in
from 
(
select
explode(split(regexp_replace(regexp_replace(options,'\\\\]|\\\\[',''),'\\\\}\\\\,\\\\{','\\\\}\\\\;\\\\{'),'\\\\;')) as cols
from 
tmp_project_field_option_str1
) t1

union all
select 
distinct 
get_json_object(cols,'$.uuid') as option_uuid,
get_json_object(cols,'$.name') as option_value,
'1' as is_built_in
from 
(
select 
explode(split(regexp_replace(regexp_replace(statuses,'\\\\]|\\\\[',''),'\\\\}\\\\,\\\\{','\\\\}\\\\;\\\\{'),'\\\\;')) as cols
from 
tmp_project_field_option_str2
) t2
"


printf "##############################################start-executor-sql####################################################################\n$sql\n##############################################end-executor-sql####################################################################"

$hive -e "$sql"
