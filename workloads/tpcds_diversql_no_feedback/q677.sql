/* goal: Compute average total profit per year for California stores selling Brand#12 items, using only sales that have no matching web return, and include all selected TPC‑DS tables. */
WITH base_sales AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        ss.ss_net_profit               AS store_profit,
        cs.cs_net_profit               AS catalog_profit,
        ws.ws_net_profit               AS web_profit,
        cs.cs_order_number,
        ws.ws_order_number
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = cs.cs_order_number
    )
),
sales_agg AS (
    SELECT
        d_year,
        s_store_name,
        i_category,
        SUM(store_profit)   AS total_store_profit,
        SUM(catalog_profit) AS total_catalog_profit,
        SUM(web_profit)     AS total_web_profit,
        SUM(store_profit + catalog_profit + web_profit) AS total_profit
    FROM base_sales
    WHERE d_year BETWEEN 1999 AND 2001
      AND i_brand = 'Brand#12'
      AND s_state = 'CA'
    GROUP BY d_year, s_store_name, i_category
)
SELECT
    d_year,
    AVG(total_profit)            AS avg_total_profit,
    COUNT(DISTINCT s_store_name) AS store_count
FROM sales_agg
GROUP BY d_year
ORDER BY avg_total_profit DESC
LIMIT 100
