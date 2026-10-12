WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_sales_price
    FROM catalog_sales cs
)
SELECT
    i.i_brand,
    i.i_item_id,
    d_sold.d_year,
    sm.sm_code,
    r.r_reason_desc,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS brand_rank,
    l.avg_price
FROM sales_base cs
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN LATERAL (
    SELECT AVG(cs3.cs_sales_price) AS avg_price
    FROM catalog_sales cs3
    WHERE cs3.cs_item_sk = i.i_item_sk
) l ON true
JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_open
    ON ws.web_close_date_sk = d_open.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = i.i_item_sk
      AND wr2.wr_return_amt > 0
)
GROUP BY
    i.i_brand,
    i.i_item_id,
    d_sold.d_year,
    sm.sm_code,
    r.r_reason_desc,
    l.avg_price
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
