WITH filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        ss.ss_ext_sales_price,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_ship_cost,
        ss.ss_quantity,
        ss.ss_sales_price
    FROM store_returns AS sr
    JOIN store_sales AS ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_returned_date_sk BETWEEN 2451500 AND 2452600
      AND sr.sr_return_amt_inc_tax > 100.00
      AND sr.sr_return_ship_cost < 500.00
      AND ss.ss_quantity >= 1
      AND ss.ss_ext_sales_price > 0
      AND ss.ss_sales_price < 5000
      AND sr.sr_returned_date_sk <> 2451987
),
with_ratio AS (
    SELECT
        f.sr_store_sk,
        f.sr_returned_date_sk,
        f.sr_return_amt_inc_tax,
        f.sr_return_ship_cost,
        f.ss_ext_sales_price,
        f.ss_quantity,
        f.ss_sales_price,
        lr.return_to_sale_ratio
    FROM filtered f
    CROSS JOIN LATERAL (
        SELECT f.sr_return_amt_inc_tax / NULLIF(f.ss_ext_sales_price, 0) AS return_to_sale_ratio
    ) lr
),
agg AS (
    SELECT
        wr.sr_store_sk,
        wr.sr_returned_date_sk,
        SUM(wr.sr_return_amt_inc_tax) AS total_return_amt,
        SUM(wr.ss_ext_sales_price) AS total_sales,
        AVG(wr.return_to_sale_ratio) AS avg_return_to_sale_ratio
    FROM with_ratio wr
    GROUP BY ROLLUP (wr.sr_store_sk, wr.sr_returned_date_sk)
)
SELECT
    agg.sr_store_sk,
    agg.sr_returned_date_sk,
    agg.total_return_amt,
    agg.total_sales,
    agg.avg_return_to_sale_ratio,
    ROW_NUMBER() OVER (ORDER BY agg.total_return_amt DESC) AS row_num
FROM agg
ORDER BY row_num
LIMIT 100
