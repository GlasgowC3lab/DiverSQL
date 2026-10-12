WITH sales_filtered AS (
    SELECT *
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_category = 'Books'
    )
),
sales_excluding_returns AS (
    SELECT cs.cs_order_number
    FROM sales_filtered cs
    EXCEPT
    SELECT wr.wr_order_number
    FROM web_returns wr
),
joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        i_sales.i_category,
        d_sold.d_year,
        hd_bill.hd_buy_potential,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i_return.i_category AS return_category,
        d_return.d_year AS return_year,
        hd_refunded.hd_buy_potential AS refunded_buy_potential
    FROM sales_filtered cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN item i_sales ON cs.cs_item_sk = i_sales.i_item_sk
    LEFT JOIN web_returns wr ON cs.cs_order_number = wr.wr_order_number
    LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN item i_return ON wr.wr_item_sk = i_return.i_item_sk
    LEFT JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM sales_excluding_returns)
)
SELECT
    i_category,
    d_year,
    hd_buy_potential,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM joined
GROUP BY CUBE (i_category, d_year, hd_buy_potential)
ORDER BY total_net_profit DESC
LIMIT 100
