SELECT
    d_sold.d_year,
    d_sold.d_quarter_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_quantity) AS total_qty_sold,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    COUNT(DISTINCT wr.wr_order_number) AS returns_cnt,
    SUM(wr.wr_return_quantity) AS total_qty_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt) AS net_sales_after_returns,
    ROUND(
        CASE WHEN SUM(cs.cs_net_paid) = 0 THEN 0
             ELSE (SUM(cs.cs_net_profit) - SUM(wr.wr_net_loss)) / SUM(cs.cs_net_paid)
        END, 4
    ) AS net_profit_margin
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_sold.d_year BETWEEN 1997 AND 1999
  AND i.i_category = 'Electronics'
  AND s.s_state IS NOT NULL
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    i.i_category,
    i.i_brand,
    s.s_state
HAVING SUM(cs.cs_net_paid) > 50000
ORDER BY net_sales_after_returns DESC
LIMIT 100
