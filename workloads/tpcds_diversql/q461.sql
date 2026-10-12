WITH order_set AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
    EXCEPT
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_profit < 0
),
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM order_set)
)
SELECT
    d_sold.d_year,
    d_ship.d_month_seq,
    d_ship2.d_quarter_name,
    i1.i_category,
    i2.i_brand,
    hd_bill.hd_buy_potential,
    hd_ship.hd_vehicle_count,
    CASE WHEN b.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (SELECT SUM(cs_inner.cs_ext_sales_price)
     FROM catalog_sales cs_inner
     WHERE cs_inner.cs_item_sk = b.cs_item_sk) AS total_sales_for_item,
    SUM(b.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT b.cs_order_number) AS orders_count
FROM base b
JOIN date_dim d_sold
  ON b.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON b.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_ship2
  ON b.cs_ship_date_sk = d_ship2.d_date_sk
JOIN household_demographics hd_bill
  ON b.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON b.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN item i1
  ON b.cs_item_sk = i1.i_item_sk
JOIN item i2
  ON b.cs_item_sk = i2.i_item_sk
FULL OUTER JOIN web_site ws_open
  ON ws_open.web_open_date_sk = d_sold.d_date_sk
FULL OUTER JOIN web_site ws_close
  ON ws_close.web_close_date_sk = d_ship.d_date_sk
GROUP BY
    d_sold.d_year,
    d_ship.d_month_seq,
    d_ship2.d_quarter_name,
    i1.i_category,
    i2.i_brand,
    hd_bill.hd_buy_potential,
    hd_ship.hd_vehicle_count,
    CASE WHEN b.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
    b.cs_item_sk
ORDER BY total_net_paid DESC
LIMIT 100
