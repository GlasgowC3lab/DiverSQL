WITH catalog_agg AS (
    SELECT
        c.cs_order_number,
        d.d_year,
        cp.cp_department,
        w.w_warehouse_name,
        SUM(c.cs_ext_sales_price) AS catalog_sales_total,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales c
    JOIN date_dim d ON c.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON c.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON c.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_catalog_number IN (5, 13, 18)
      AND d.d_year BETWEEN 1999 AND 2001
      AND c.cs_promo_sk IN (
          SELECT cs_promo_sk
          FROM catalog_sales
          WHERE cs_ext_ship_cost > 400
      )
    GROUP BY c.cs_order_number, d.d_year, cp.cp_department, w.w_warehouse_name
),
store_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND d.d_month_seq BETWEEN 1200 AND 1300
    GROUP BY s.s_store_id, d.d_year
),
web_agg AS (
    SELECT
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_quantity > 5
    GROUP BY d.d_year
)
SELECT
    ca.d_year,
    ca.cp_department,
    ca.w_warehouse_name,
    ca.catalog_sales_total,
    sa.store_sales_total,
    wa.web_sales_total,
    ROW_NUMBER() OVER (PARTITION BY ca.d_year ORDER BY sa.store_sales_total DESC) AS store_sales_rank,
    AVG(ca.catalog_sales_total) OVER (PARTITION BY ca.d_year) AS avg_catalog_sales_total_per_year
FROM catalog_agg ca
LEFT JOIN store_agg sa ON ca.d_year = sa.d_year
LEFT JOIN web_agg wa ON ca.d_year = wa.d_year
ORDER BY ca.d_year, ca.catalog_sales_total DESC
LIMIT 100
