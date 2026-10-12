WITH sales_agg AS (
    SELECT
        d_sales.d_date AS sale_date,
        d_closed.d_date AS store_closed_date,
        s.s_store_id,
        i.i_item_id,
        i.i_category,
        s.s_tax_percentage,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        SUM(wr.wr_return_amt) AS total_return_amount,
        CASE
            WHEN SUM(ss.ss_quantity) = 0 THEN 0
            ELSE SUM(wr.wr_return_quantity) / SUM(ss.ss_quantity)
        END AS return_rate,
        DATE_DIFF('day', d_sales.d_date, d_closed.d_date) AS days_to_store_closure
    FROM date_dim d_sales
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sales.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    GROUP BY
        d_sales.d_date,
        d_closed.d_date,
        s.s_store_id,
        i.i_item_id,
        i.i_category,
        s.s_tax_percentage
)
SELECT
    sale_date,
    store_closed_date,
    s_store_id,
    i_item_id,
    i_category,
    s_tax_percentage,
    total_quantity_sold,
    total_sales_amount,
    total_net_paid,
    total_quantity_returned,
    total_return_amount,
    return_rate,
    days_to_store_closure,
    ROW_NUMBER() OVER (PARTITION BY sale_date ORDER BY total_sales_amount DESC) AS sales_rank
FROM sales_agg
ORDER BY sale_date DESC, sales_rank
LIMIT 100
