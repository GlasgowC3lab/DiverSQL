WITH monthly_sales AS (
  SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    cd_ship.cd_gender AS ship_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cs.cs_item_sk,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    COUNT(*) AS sales_cnt,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  WHERE cs.cs_call_center_sk IN (8, 19)
    AND cs.cs_warehouse_sk = 14
    AND d_sold.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    AND cs.cs_ext_sales_price > 1000
  GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    cd_ship.cd_gender,
    cd_bill.cd_marital_status,
    cs.cs_item_sk
)
SELECT *
FROM (
  SELECT
    d_year,
    d_month_seq,
    ship_gender,
    bill_marital_status,
    cs_item_sk,
    total_profit,
    total_discount,
    avg_sales_price,
    sales_cnt,
    avg_ship_delay,
    RANK() OVER (PARTITION BY d_year, d_month_seq, ship_gender ORDER BY total_profit DESC) AS profit_rank
  FROM monthly_sales
) ranked
WHERE profit_rank <= 5
  AND total_profit > 5000
ORDER BY d_year, d_month_seq, ship_gender, profit_rank
