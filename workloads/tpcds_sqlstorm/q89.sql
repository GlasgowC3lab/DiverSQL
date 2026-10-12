WITH cat AS (
    SELECT
        d.d_year AS year,
        cc.cc_state AS region,
        SUM(cs.cs_ext_sales_price) AS sales,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_ext_discount_amt) AS discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, cc.cc_state
), store AS (
    SELECT
        d.d_year AS year,
        s.s_state AS region,
        SUM(ss.ss_ext_sales_price) AS sales,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_ext_discount_amt) AS discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, s.s_state
), web AS (
    SELECT
        d.d_year AS year,
        wp.wp_type AS region,
        SUM(ws.ws_ext_sales_price) AS sales,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_ext_discount_amt) AS discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, wp.wp_type
)
SELECT
    COALESCE(cat.year, store.year, web.year) AS year,
    COALESCE(cat.region, store.region, web.region) AS region,
    COALESCE(cat.sales, 0) AS cat_sales,
    COALESCE(store.sales, 0) AS store_sales,
    COALESCE(web.sales, 0) AS web_sales,
    COALESCE(cat.profit, 0) AS cat_profit,
    COALESCE(store.profit, 0) AS store_profit,
    COALESCE(web.profit, 0) AS web_profit,
    COALESCE(cat.discount, 0) AS cat_discount,
    COALESCE(store.discount, 0) AS store_discount,
    COALESCE(web.discount, 0) AS web_discount
FROM cat
FULL OUTER JOIN store ON cat.year = store.year AND cat.region = store.region
FULL OUTER JOIN web ON COALESCE(cat.year, store.year) = web.year AND COALESCE(cat.region, store.region) = web.region
ORDER BY year, region
