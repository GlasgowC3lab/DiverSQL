WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month,
        p.p_promo_name,
        s.s_store_name,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
        SUM(ws.ws_net_paid) AS total_sales_net,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT CASE WHEN wr.wr_returned_date_sk IS NOT NULL THEN ws.ws_order_number END) AS total_returns,
        AVG(CASE 
                WHEN wr.wr_returned_date_sk IS NOT NULL THEN DATE_DIFF('day', d_sold.d_date, d_return.d_date)
            END) AS avg_days_to_return
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        p.p_promo_name,
        s.s_store_name,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    sale_year,
    sale_month,
    p_promo_name,
    s_store_name,
    promo_start_date,
    promo_end_date,
    promo_duration_days,
    total_sales_net,
    total_orders,
    total_return_amt,
    total_returns,
    avg_days_to_return,
    (total_sales_net - total_return_amt) AS net_profit_adj,
    ROUND((total_return_amt / NULLIF(total_sales_net, 0)) * 100, 2) AS return_rate_percent,
    ROW_NUMBER() OVER (PARTITION BY sale_year ORDER BY (total_sales_net - total_return_amt) DESC) AS profit_rank_in_year
FROM sales_agg
ORDER BY net_profit_adj DESC
LIMIT 100
