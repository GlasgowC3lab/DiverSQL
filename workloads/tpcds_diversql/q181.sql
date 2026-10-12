WITH
subq1 AS (
    SELECT
        promo1.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
    JOIN promotion promo1 ON ss.ss_promo_sk = promo1.p_promo_sk
    JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td2.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion promo2 ON ss.ss_promo_sk = promo2.p_promo_sk
    JOIN time_dim td3 ON sr.sr_return_time_sk = td3.t_time_sk
    JOIN time_dim td4 ON cr.cr_returned_time_sk = td4.t_time_sk
    WHERE promo1.p_channel_dmail = 'Y'
      AND td1.t_hour BETWEEN 8 AND 12
    GROUP BY promo1.p_promo_name, w.w_warehouse_name
),
subq2 AS (
    SELECT
        promo1.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
    JOIN promotion promo1 ON ss.ss_promo_sk = promo1.p_promo_sk
    JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td2.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion promo2 ON ss.ss_promo_sk = promo2.p_promo_sk
    JOIN time_dim td3 ON sr.sr_return_time_sk = td3.t_time_sk
    JOIN time_dim td4 ON cr.cr_returned_time_sk = td4.t_time_sk
    WHERE promo2.p_channel_email = 'N'
      AND td1.t_hour BETWEEN 13 AND 18
    GROUP BY promo1.p_promo_name, w.w_warehouse_name
),
subq3 AS (
    SELECT
        promo1.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
    JOIN promotion promo1 ON ss.ss_promo_sk = promo1.p_promo_sk
    JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td2.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion promo2 ON ss.ss_promo_sk = promo2.p_promo_sk
    JOIN time_dim td3 ON sr.sr_return_time_sk = td3.t_time_sk
    JOIN time_dim td4 ON cr.cr_returned_time_sk = td4.t_time_sk
    WHERE td1.t_hour = 15
      AND w.w_city = 'Seattle'
    GROUP BY promo1.p_promo_name, w.w_warehouse_name
)
SELECT promo_name, warehouse_name, total_profit
FROM subq1
EXCEPT
SELECT promo_name, warehouse_name, total_profit
FROM subq2
INTERSECT
SELECT promo_name, warehouse_name, total_profit
FROM subq3
LIMIT 100
