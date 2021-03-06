/********************************************************************************************************
*                                                                                                       *
*                                       Snowflake Data Profiler                                         *
*                                                                                                       *
*  Copyright (c) 2020 Snowflake Computing Inc. All rights reserved.                                     *
*                                                                                                       *
*  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in  *
*. compliance with the License. You may obtain a copy of the License at                                 *
*                                                                                                       *
*                               http://www.apache.org/licenses/LICENSE-2.0                              *
*                                                                                                       *
*  Unless required by applicable law or agreed to in writing, software distributed under the License    *
*  is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or  *
*  implied. See the License for the specific language governing permissions and limitations under the   *
*  License.                                                                                             *
*                                                                                                       *
*  Copyright (c) 2020 Snowflake Computing Inc. All rights reserved.                                     *
*                                                                                                       *
********************************************************************************************************/

/********************************************************************************************************
*                                                                                                       *
*  Profile the columns by name. Execution speed is approximately 300 columns per second.                *
*                                                                                                       *
********************************************************************************************************/
call DATA_PROFILE_COLUMN_NAMES('.*', '.*', '.*', '.*');

/********************************************************************************************************
*                                                                                                       *
*  Examine the results of the column name profile.                                                      *
*                                                                                                       *
********************************************************************************************************/
select * from DATA_PROFILE_COLUMN_NAMES
order by SEEMS_TO_HAVE, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, COLUMN_NAME;

-- Find likely single-column primary keys based on column name match and ordinal position = 1
select * from DATA_PROFILE_COLUMN_NAMES
where RULE_NAME = 'en_PRIMARY_KEY' and ORDINAL_POSITION = 1;

/********************************************************************************************************
*                                                                                                       *
*  Optionally set the WHERE_CLUSE as a variable (can be any variable name). If you need to use single   *
*  to quotes in your where clause, remember to escape them using backslashes or double them. The where  *
*. clause is passthrough. If it causes a SQL error, the stored procedure will terminate. If you do not  *
*  need to specify a where clause, use a blank string for the WHERE_CLAUSE parameter.                   *
*                                                                                                       *
********************************************************************************************************/
set WHERE_CLAUSE = '';
select $WHERE_CLAUSE; --Confirm the where clause is correct, especially the single quotes if required.

/********************************************************************************************************
*                                                                                                       *
*  Profile the columns by data contents. Execution speed is approximately 0.25 columns per second when  *
*  using SAMPLING_STRATEGY "limit" and SAMPLING_VALUE = 100,000                                         *
*  This example profiles only one table using a WHERE clause to profile only newer rows.                *
*                                                                                                       *
********************************************************************************************************/
call data_profile_columns(
                           'SNOWFLAKE_SAMPLE_DATA',      -- The database name or regex pattern to profile
                           'TPCH_SF1',                   -- The schema name or regex pattern to profile
                           '.*',                     -- The table name or regex pattern to profile
                           '.*',                         -- The column name or regex pattern to profile
                           'limit',                      -- Sample strategy, 'limit' or 'sample'. Do not use a where clause if 'sample'.
                           100000,                       -- Number of rows to sample
                           90,                           -- Days before updating an older profile
                           2,                            -- Max runtime minutes, will end where left
                           $WHERE_CLAUSE                 -- Where cluase for sample or blank if none. Do not use a whare clause if sample strategy is 'sample'
                         );

/********************************************************************************************************
*                                                                                                       *
*  Profile the columns by data contents. Execution speed is approximately 0.5 columns per second when   *
*  using SAMPLING_STRATEGY "sample" and SAMPLING_VALUE = 10,000                                         *
*  This example profiles an entire schema. It will not re-profile the columns profiled in the last      * 
*  execution of this stored procedure, because they're run within the re-profile setting.               *
*                                                                                                       *
********************************************************************************************************/
call data_profile_columns(
                           'SNOWFLAKE_SAMPLE_DATA',      -- The database name or regex pattern to profile
                           '.*',                         -- The schema name or regex pattern to profile
                           '.*',                         -- The table name or regex pattern to profile
                           '.*',                         -- The column name or regex pattern to profile
                           'sample',                     -- Sample strategy, 'limit' or 'sample'
                           10000,                        -- Number of rows to sample
                           90,                           -- Days before updating an older profile
                           20,                           -- Max runtime minutes, will end where left
                           ''                            -- Where cluase for sample or blank if none
                         );

/********************************************************************************************************
*                                                                                                       *
*  Examine the results of the query profile.                                                            *
*                                                                                                       *
********************************************************************************************************/
select * from DATA_PROFILE;

-- Check for columns with possible single-column primary key candidates:
select * from DATA_PROFILE where IS_UNIQUE;


/********************************************************************************************************
*                                                                                                       *
*  Sample query to check for important data type mismatches                                             *
*                                                                                                       *
********************************************************************************************************/
select * from DATA_PROFILE where HAS_TYPE_MISMATCH
