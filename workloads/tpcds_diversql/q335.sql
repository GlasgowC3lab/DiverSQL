/*
Goal: Identify brand‑category combinations with the highest net loss from store returns, comparing two distinct filter sets (different years/brands) and ranking them per brand.
*/
WITH
-- First filtered set (Year 2001, Brand#12, good credit rating, business hours, promotion channel event N)
base_a AS (
    SELECT
        i.i_brand,
        i.i_category,
        d.d_year,
        sr.sr_customer_sk,
        sr.sr_net_loss,
        sr.sr_return_quantity
    FROM tpcds.store_returns sr
    FULL OUTER JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    INNER JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    INNER JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.promotion pr
        ON cs.cs_promo_sk = pr.p_promo_sk
    LEFT JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_credit_rating = 'Good'
      AND i.i_brand = 'Brand#12'
      AND pr.p_channel_event = 'N'
),
agg_a AS (
    SELECT
        i_brand,
        i_category,
        d_year,
        SUM(sr_return_quantity)   AS total_return_qty,
        SUM(sr_net_loss)          AS total_net_loss,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers
    FROM base_a
    GROUP BY i_brand, i_category, d_year
),
-- Second filtered set (Year 2002, Brand#23, high risk credit rating, evening hours, promotion channel event N)
base_b AS (
    SELECT
        i.i_brand,
        i.i_category,
        d.d_year,
        sr.sr_customer_sk,
        sr.sr_net_loss,
        sr.sr_return_quantity
    FROM tpcds.store_returns sr
    FULL OUTER JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN tpcds.date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    INNER JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    INNER JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.promotion pr
        ON cs.cs_promo_sk = pr.p_promo_sk
    LEFT JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 18 AND 23
      AND cd.cd_credit_rating = 'High Risk'
      AND i.i_brand = 'Brand#23'
      AND pr.p_channel_event = 'N'
),
agg_b AS (
    SELECT
        i_brand,
        i_category,
        d_year,
        SUM(sr_return_quantity)   AS total_return_qty,
        SUM(sr_net_loss)          AS total_net_loss,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers
    FROM base_b
    GROUP BY i_brand, i_category, d_year
),
-- Union the two aggregated result sets (DISTINCT is implicit in UNION)
unioned AS (
    SELECT * FROM agg_a
    UNION
    SELECT * FROM agg_b
)
SELECT
    i_brand,
    i_category,
    d_year,
    total_return_qty,
    total_net_loss,
    distinct_customers,
    CASE WHEN total_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_type,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_net_loss DESC) AS loss_rank
FROM unioned
ORDER BY loss_rank, total_net_loss DESC
LIMIT 100
