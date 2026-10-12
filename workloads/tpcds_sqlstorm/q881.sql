WITH sales_agg AS (
   SELECT 
       coalesce(cs.cs_bill_customer_sk, ss.ss_customer_sk, ws.ws_bill_customer_sk) AS customer_sk,
       sum(cs.cs_net_profit) AS cat_net_profit,
       sum(ss.ss_net_profit) AS store_net_profit,
       sum(ws.ws_net_profit) AS web_net_profit,
       sum(coalesce(cs.cs_net_profit,0) + coalesce(ss.ss_net_profit,0) + coalesce(ws.ws_net_profit,0)) AS total_net_profit,
       count(DISTINCT cs.cs_order_number) AS cat_order_cnt,
       count(DISTINCT ss.ss_ticket_number) AS store_order_cnt,
       count(DISTINCT ws.ws_order_number) AS web_order_cnt,
       max(date_dim.d_year) AS max_year
   FROM 
       catalog_sales cs
       FULL OUTER JOIN store_sales ss
         ON ss.ss_ticket_number = cs.cs_order_number
       FULL OUTER JOIN web_sales ws
         ON ws.ws_order_number = coalesce(cs.cs_order_number, ss.ss_ticket_number)
       LEFT JOIN date_dim
         ON date_dim.d_date_sk = coalesce(cs.cs_sold_date_sk, ss.ss_sold_date_sk, ws.ws_sold_date_sk)
   GROUP BY 1
),
returns_agg AS (
   SELECT 
       coalesce(cr.cr_returning_customer_sk, sr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
       sum(cr.cr_net_loss) AS cat_return_loss,
       sum(sr.sr_net_loss) AS store_return_loss,
       sum(wr.wr_net_loss) AS web_return_loss,
       sum(coalesce(cr.cr_net_loss,0) + coalesce(sr.sr_net_loss,0) + coalesce(wr.wr_net_loss,0)) AS total_return_loss,
       count(*) AS total_return_cnt
   FROM 
       catalog_returns cr
       FULL OUTER JOIN store_returns sr
         ON sr.sr_ticket_number = cr.cr_order_number
       FULL OUTER JOIN web_returns wr
         ON wr.wr_order_number = coalesce(cr.cr_order_number, sr.sr_ticket_number)
   GROUP BY 1
),
cust_demo AS (
   SELECT 
       c.c_customer_sk,
       concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
       c.c_birth_country,
       cd.cd_gender,
       cd.cd_education_status,
       hd.hd_buy_potential,
       CASE 
           WHEN cd.cd_credit_rating IS NULL THEN 'UNKNOWN'
           ELSE cd.cd_credit_rating
       END AS credit_rating,
       nullif(cd.cd_dep_count,0) AS dep_count_nonzero,
       c.c_email_address
   FROM 
       customer c
       LEFT JOIN customer_demographics cd 
         ON cd.cd_demo_sk = c.c_current_cdemo_sk
       LEFT JOIN household_demographics hd 
         ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
enriched AS (
   SELECT 
       s.customer_sk,
       cd.full_name,
       cd.c_birth_country,
       cd.cd_gender,
       cd.cd_education_status,
       cd.hd_buy_potential,
       cd.credit_rating,
       s.total_net_profit,
       r.total_return_loss,
       coalesce(s.total_net_profit,0) - coalesce(r.total_return_loss,0) AS net_profit_after_returns,
       CASE 
           WHEN coalesce(s.total_net_profit,0) > 0 
                AND coalesce(r.total_return_loss,0) / nullif(coalesce(s.total_net_profit,0), 0) > 0.5 THEN 'HIGH_RISK'
           WHEN coalesce(s.total_net_profit,0) < 0 THEN 'LOSS'
           ELSE 'OK'
       END AS profit_status,
       row_number() OVER (ORDER BY (coalesce(s.total_net_profit,0) - coalesce(r.total_return_loss,0)) DESC) AS rn,
       concat('Customer-', cast(s.customer_sk AS varchar), ':', coalesce(cd.full_name, 'UNKNOWN')) AS label,
       try_cast(substr(cd.c_email_address, 1, 10) AS integer) AS email_prefix_int,
       coalesce(s.max_year, 2000) - 2000 AS years_since_2000,
       (SELECT count(DISTINCT cs_item_sk) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = s.customer_sk) AS cat_distinct_items,
       r.total_return_cnt
   FROM 
       sales_agg s
       LEFT JOIN returns_agg r
         ON r.customer_sk = s.customer_sk
       LEFT JOIN cust_demo cd
         ON cd.c_customer_sk = s.customer_sk
)
SELECT 
   e.rn,
   e.customer_sk,
   e.label,
   e.net_profit_after_returns,
   e.profit_status,
   e.full_name,
   e.c_birth_country,
   e.cd_gender,
   e.cd_education_status,
   e.hd_buy_potential,
   e.credit_rating,
   e.email_prefix_int,
   e.years_since_2000,
   e.cat_distinct_items
FROM 
   enriched e
WHERE 
   e.rn <= 10
   AND (e.profit_status = 'HIGH_RISK' OR e.profit_status = 'OK')
   AND (e.cd_gender IS NOT DISTINCT FROM 'M' OR e.cd_gender IS NULL)
   AND (e.c_birth_country = 'United States' OR e.c_birth_country IS NULL)
   AND e.full_name NOT LIKE '%Test%'
UNION ALL
SELECT 
   NULL AS rn,
   NULL AS customer_sk,
   'SUMMARY' AS label,
   sum(e.net_profit_after_returns) AS net_profit_after_returns,
   NULL AS profit_status,
   NULL AS full_name,
   NULL AS c_birth_country,
   NULL AS cd_gender,
   NULL AS cd_education_status,
   NULL AS hd_buy_potential,
   NULL AS credit_rating,
   NULL AS email_prefix_int,
   NULL AS years_since_2000,
   NULL AS cat_distinct_items
FROM 
   enriched e
WHERE 
   e.rn <= 10
   AND e.profit_status = 'HIGH_RISK'
INTERSECT
SELECT 
   e.rn,
   e.customer_sk,
   e.label,
   e.net_profit_after_returns,
   e.profit_status,
   e.full_name,
   e.c_birth_country,
   e.cd_gender,
   e.cd_education_status,
   e.hd_buy_potential,
   e.credit_rating,
   e.email_prefix_int,
   e.years_since_2000,
   e.cat_distinct_items
FROM 
   enriched e
WHERE 
   e.net_profit_after_returns > 0
   AND e.total_return_cnt IS NOT NULL
EXCEPT
SELECT 
   e.rn,
   e.customer_sk,
   e.label,
   e.net_profit_after_returns,
   e.profit_status,
   e.full_name,
   e.c_birth_country,
   e.cd_gender,
   e.cd_education_status,
   e.hd_buy_potential,
   e.credit_rating,
   e.email_prefix_int,
   e.years_since_2000,
   e.cat_distinct_items
FROM 
   enriched e
WHERE 
   e.profit_status = 'LOSS'
