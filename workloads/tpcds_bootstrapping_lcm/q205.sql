WITH sales_data AS (
    SELECT
        d_sold.d_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MAX(ss.ss_ext_tax) AS max_ext_tax,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
        CASE WHEN d_closed.d_date IS NOT NULL THEN 1 ELSE 0 END AS is_store_closed,
        (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns,
        (SUM(ss.ss_ext_sales_price) / NULLIF(SUM(i.inv_quantity_on_hand), 0)) AS sales_per_inventory
    FROM date_dim d_sold
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        d_sold.d_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_closed.d_date
)
SELECT
    sd.*,
    ROW_NUMBER() OVER (PARTITION BY sd.s_state ORDER BY sd.total_sales DESC) AS sales_rank_by_state
FROM sales_data sd
ORDER BY sd.total_sales DESC
LIMIT 100
