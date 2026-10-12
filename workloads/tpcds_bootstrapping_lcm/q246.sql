WITH promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_cost,
        DATE_DIFF('day', d_start.d_date, d_end.d_date) AS promo_duration_days
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
),
sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT cs.cs_order_number)                              AS num_orders,
        SUM(cs.cs_net_paid)                                             AS total_sales,
        SUM(cs.cs_net_profit)                                           AS total_profit,
        COALESCE(SUM(wr.wr_return_amt), 0)                              AS total_returns,
        SUM(promo.p_cost)                                               AS total_promo_cost,
        SUM(promo.promo_duration_days * promo.p_cost)                  AS weighted_promo_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promo_info promo ON cs.cs_promo_sk = promo.p_promo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_city, d.d_year, d.d_month_seq
)
SELECT
    s_store_id,
    s_city,
    d_year,
    d_month_seq,
    num_orders,
    total_sales,
    total_profit,
    total_returns,
    total_promo_cost,
    weighted_promo_cost,
    (total_sales - total_returns - total_promo_cost) / NULLIF(total_sales, 0) AS net_margin,
    ROW_NUMBER() OVER (
        PARTITION BY s_store_id
        ORDER BY (total_sales - total_returns - total_promo_cost) / NULLIF(total_sales, 0) DESC
    ) AS margin_rank
FROM sales_agg
ORDER BY net_margin DESC
LIMIT 100
