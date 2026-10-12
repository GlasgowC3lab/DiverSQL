WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        i.i_item_id,
        cd.cd_credit_rating,
        c.c_customer_id,
        ca.ca_state,
        s.s_state AS store_state,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt,
        ws.ws_ext_sales_price,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND inv.inv_quantity_on_hand > 500
)
SELECT *
FROM (
    SELECT
        d_year,
        i_brand,
        CASE WHEN cd_credit_rating = 'Good' THEN 'Preferred' ELSE 'Standard' END AS customer_segment,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        COUNT(DISTINCT i_item_id) AS distinct_items,
        SUM(cs_ext_sales_price) AS total_sales_amount,
        SUM(cr_return_amount) AS total_catalog_returns,
        SUM(sr_return_amt) AS total_store_returns,
        SUM(ws_ext_sales_price) AS total_web_sales,
        AVG(cs_net_profit) AS avg_sales_profit,
        MIN(cs_net_profit) AS min_sales_profit,
        MAX(cs_net_profit) AS max_sales_profit,
        (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = base.store_state) AS stores_in_state
    FROM base
    GROUP BY d_year, i_brand, cd_credit_rating, store_state
) 
UNION DISTINCT
SELECT
    d_year,
    i_brand,
    CASE WHEN cd_credit_rating = 'Good' THEN 'Preferred' ELSE 'Standard' END AS customer_segment,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    SUM(cs_ext_sales_price) AS total_sales_amount,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(ws_ext_sales_price) AS total_web_sales,
    AVG(cs_net_profit) AS avg_sales_profit,
    MIN(cs_net_profit) AS min_sales_profit,
    MAX(cs_net_profit) AS max_sales_profit,
    (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = base.store_state) AS stores_in_state
FROM base
GROUP BY d_year, i_brand, cd_credit_rating, store_state
ORDER BY total_sales_amount DESC
LIMIT 100
