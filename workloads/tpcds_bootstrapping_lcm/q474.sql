WITH cs AS (
    SELECT cs.*, 
           d_sold.d_year AS sold_year,
           d_sold.d_month_seq AS sold_month,
           d_ship.d_year AS ship_year,
           d_ship.d_month_seq AS ship_month
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
), wr AS (
    SELECT wr.*, 
           d_return.d_year AS return_year,
           d_return.d_month_seq AS return_month
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
), s AS (
    SELECT s.*, 
           d_closed.d_year AS closed_year,
           d_closed.d_month_seq AS closed_month
    FROM store s
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
), ws AS (
    SELECT ws.*, 
           d_open.d_year AS open_year,
           d_open.d_month_seq AS open_month,
           d_close.d_year AS close_year,
           d_close.d_month_seq AS close_month
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
)
SELECT
    cs.sold_year,
    cs.sold_month,
    cs.ship_month,
    s.s_state,
    ws.web_state,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 0
         THEN SUM(wr.wr_return_amt) / SUM(cs.cs_ext_sales_price)
         ELSE NULL END AS return_rate,
    (SUM(cs.cs_ext_sales_price) - SUM(wr.wr_return_amt)) AS net_sales_after_returns,
    ((SUM(cs.cs_ext_sales_price) - SUM(wr.wr_return_amt)) - SUM(cs.cs_ext_discount_amt) - SUM(cs.cs_ext_tax)) AS net_revenue_adj,
    (SUM(cs.cs_ext_sales_price) * 0.05) AS estimated_tax_estimate,
    (SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_discount_amt) - SUM(cs.cs_ext_tax)) / NULLIF(SUM(cs.cs_quantity), 0) AS avg_price_per_unit
FROM cs
JOIN wr ON cs.sold_year = wr.return_year AND cs.sold_month = wr.return_month
JOIN s ON s.closed_year = cs.sold_year AND s.closed_month = cs.sold_month
JOIN ws ON ws.open_year = cs.sold_year AND ws.open_month = cs.sold_month
WHERE cs.cs_quantity > 0
GROUP BY cs.sold_year, cs.sold_month, cs.ship_month, s.s_state, ws.web_state
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY cs.sold_year DESC, cs.sold_month
LIMIT 100
