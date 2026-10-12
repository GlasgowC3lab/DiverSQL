WITH base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ext_sales_price,
        cp.cp_catalog_page_id,
        cp.cp_department,
        w.w_state,
        d_sold.d_year,
        t.t_hour,
        ca.ca_country,
        ib.ib_upper_bound
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 1999
      AND t.t_hour BETWEEN 9 AND 17
      AND ca.ca_country = 'United States'
      AND ib.ib_upper_bound <= 5000
),
agg1 AS (
    SELECT
        cp_catalog_page_id,
        cp_department,
        w_state,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM base
    GROUP BY cp_catalog_page_id, cp_department, w_state
),
agg2 AS (
    SELECT
        cp_department,
        AVG(total_sales) AS avg_sales_dept
    FROM agg1
    GROUP BY cp_department
)
SELECT
    a1.cp_catalog_page_id,
    a1.cp_department,
    a1.w_state,
    a1.total_sales,
    a2.avg_sales_dept,
    ROW_NUMBER() OVER (ORDER BY a1.total_sales DESC) AS rn
FROM agg1 a1
JOIN agg2 a2
    ON a1.cp_department = a2.cp_department
WHERE a1.total_sales > a2.avg_sales_dept
  AND a1.cp_catalog_page_id NOT IN (
        SELECT cp2.cp_catalog_page_id
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'CLEARANCE'
    )
ORDER BY a1.total_sales DESC
LIMIT 100
