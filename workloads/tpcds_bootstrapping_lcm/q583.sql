WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
wr_agg AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    SUM(cs.cs_ext_tax) AS total_tax,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    wr_agg.total_return_amount,
    wr_agg.total_return_loss,
    wr_agg.num_returns,
    inv_agg.total_quantity_on_hand,
    inv_agg.avg_quantity_on_hand,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 0
         THEN SUM(cs.cs_ext_discount_amt) / SUM(cs.cs_ext_sales_price)
         ELSE NULL END AS discount_rate,
    CASE WHEN SUM(cs.cs_net_paid) > 0
         THEN wr_agg.total_return_amount / SUM(cs.cs_net_paid)
         ELSE NULL END AS return_to_sales_ratio
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN inv_agg
    ON inv_agg.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN wr_agg
    ON wr_agg.wr_returned_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    wr_agg.total_return_amount,
    wr_agg.total_return_loss,
    wr_agg.num_returns,
    inv_agg.total_quantity_on_hand,
    inv_agg.avg_quantity_on_hand
ORDER BY
    s.s_store_id,
    d_sold.d_year,
    d_sold.d_month_seq
