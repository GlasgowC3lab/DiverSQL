WITH joined_data AS (
   SELECT
       cs.cs_net_paid                                AS cs_net_paid,
       ss.ss_net_paid                                AS ss_net_paid,
       sr.sr_net_loss                                AS sr_net_loss,
       d.d_year                                      AS d_year,
       d.d_month_seq                                 AS d_month_seq,
       i.i_category                                  AS i_category,
       i.i_brand                                     AS i_brand,
       p.p_promo_name                                AS p_promo_name,
       p.p_channel_tv                                AS p_channel_tv,
       sm.sm_type                                    AS sm_type,
       r.r_reason_desc                               AS r_reason_desc,
       ws.web_manager                                AS web_manager,
       t.t_hour                                      AS t_hour
   FROM catalog_sales cs
   JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
   JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
   JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN promotion p              ON cs.cs_promo_sk      = p.p_promo_sk
   JOIN ship_mode sm             ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
   JOIN item i                   ON cs.cs_item_sk       = i.i_item_sk
   JOIN store_sales ss           ON ss.ss_item_sk       = i.i_item_sk
                                 AND ss.ss_customer_sk  = c.c_customer_sk
                                 AND ss.ss_sold_date_sk = d.d_date_sk
                                 AND ss.ss_sold_time_sk = t.t_time_sk
   JOIN store_returns sr         ON sr.sr_item_sk       = ss.ss_item_sk
                                 AND sr.sr_customer_sk  = c.c_customer_sk
                                 AND sr.sr_returned_date_sk = d.d_date_sk
                                 AND sr.sr_return_time_sk   = t.t_time_sk
                                 AND sr.sr_ticket_number     = ss.ss_ticket_number
   JOIN reason r                 ON sr.sr_reason_sk     = r.r_reason_sk
   JOIN web_site ws              ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001                              -- predicate 1
     AND i.i_brand = 'Brand#45'                        -- predicate 2
     AND p.p_channel_tv = 'Y'                          -- predicate 3
     AND sm.sm_type = 'AIR'                            -- predicate 4
     AND r.r_reason_desc LIKE '%defect%'              -- predicate 5
     AND ws.web_manager = 'James Austin'              -- predicate 6
     AND t.t_hour BETWEEN 9 AND 17                    -- predicate 7
),
agg1 AS (
   SELECT
       d_year,
       i_category,
       i_brand,
       p_promo_name,
       sm_type,
       SUM(cs_net_paid)   AS total_cs_paid,
       SUM(ss_net_paid)   AS total_ss_paid,
       SUM(sr_net_loss)   AS total_sr_loss,
       COUNT(*)           AS cnt
   FROM joined_data
   GROUP BY GROUPING SETS (
       (d_year, i_category, i_brand),
       (d_year, i_brand, p_promo_name),
       (d_year, sm_type),
       (i_category, i_brand),
       ()
   )
)
SELECT
   d_year,
   i_category,
   i_brand,
   p_promo_name,
   sm_type,
   total_cs_paid,
   total_ss_paid,
   total_sr_loss,
   cnt,
   (total_cs_paid + total_ss_paid - total_sr_loss) / NULLIF(cnt, 0) AS avg_net_contrib
FROM agg1
WHERE (total_cs_paid + total_ss_paid) > 100000            -- filter on aggregated sales
  AND total_sr_loss < 50000                                 -- filter on returns loss
  AND cnt >= 10                                             -- filter on transaction count
ORDER BY avg_net_contrib DESC
LIMIT 100
