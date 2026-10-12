WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        s.s_store_id AS location_id,
        s.s_store_name AS location_name,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_store_name, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        cc.cc_call_center_id AS location_id,
        cc.cc_name AS location_name,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
    GROUP BY d.d_year, d.d_month_seq, cc.cc_call_center_id, cc.cc_name, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        w.web_site_id AS location_id,
        w.web_name AS location_name,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
    GROUP BY d.d_year, d.d_month_seq, w.web_site_id, w.web_name, i.i_category
)
SELECT *
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) t
ORDER BY net_paid DESC
LIMIT 100
