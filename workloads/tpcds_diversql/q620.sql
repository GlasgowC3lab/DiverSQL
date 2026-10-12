WITH cs_data AS (
    SELECT
        cs.cs_order_number AS order_key,
        d.d_year AS d_year,
        hd.hd_income_band_sk AS hd_income_band_sk,
        cs.cs_net_profit AS profit,
        cs.cs_ext_sales_price AS sales,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_status,
        regexp_extract(d.d_day_name, '(\\w+)', 1) AS day_name_extracted,
        CONCAT(d.d_quarter_name, '-', hd.hd_buy_potential) AS quarter_buy_concat
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(d.d_day_name, '^S')
      AND hd.hd_buy_potential LIKE '%HIGH%'
),
ss_data AS (
    SELECT
        ss.ss_ticket_number AS order_key,
        d.d_year AS d_year,
        hd.hd_income_band_sk AS hd_income_band_sk,
        ss.ss_net_profit AS profit,
        ss.ss_ext_sales_price AS sales,
        CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_status,
        regexp_extract(d.d_day_name, '(\\w+)', 1) AS day_name_extracted,
        CONCAT(d.d_quarter_name, '-', hd.hd_buy_potential) AS quarter_buy_concat
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_day_name LIKE '%day'
      AND hd.hd_buy_potential LIKE '%LOW%'
),
intersect_orders AS (
    SELECT order_key FROM cs_data
    INTERSECT
    SELECT order_key FROM ss_data
),
union_data AS (
    SELECT
        cs.order_key,
        cs.d_year,
        cs.hd_income_band_sk,
        cs.profit_status,
        cs.profit,
        cs.sales
    FROM cs_data cs
    WHERE cs.order_key IN (SELECT order_key FROM intersect_orders)
    UNION
    SELECT
        ss.order_key,
        ss.d_year,
        ss.hd_income_band_sk,
        ss.profit_status,
        ss.profit,
        ss.sales
    FROM ss_data ss
    WHERE ss.order_key IN (SELECT order_key FROM intersect_orders)
)
SELECT
    d_year,
    hd_income_band_sk,
    profit_status,
    SUM(profit) AS total_profit,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT order_key) AS order_cnt,
    (SELECT MAX(d_year) FROM date_dim) AS max_year_overall
FROM union_data
GROUP BY CUBE (d_year, hd_income_band_sk, profit_status)
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
