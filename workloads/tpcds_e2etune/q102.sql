WITH sales_by_shift AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_quarter_name,
        d.d_current_quarter,
        t.t_shift,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_current_quarter = 'Y'
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
),
returns_by_shift AS (
    SELECT
        wr.wr_item_sk,
        d.d_year,
        d.d_quarter_name,
        t.t_shift,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_current_quarter = 'Y'
),
sales_agg AS (
    SELECT
        sb.ss_store_sk AS store_sk,
        sb.d_year,
        sb.d_quarter_name,
        sb.t_shift,
        SUM(sb.ss_quantity) AS total_units_sold,
        SUM(sb.ss_ext_sales_price) AS total_sales_amount,
        SUM(sb.ss_net_profit) AS total_net_profit,
        SUM(sb.ss_ext_discount_amt) AS total_discount,
        SUM(sb.ss_ext_tax) AS total_tax,
        SUM(COALESCE(sb.p_cost, 0)) AS total_promo_cost
    FROM sales_by_shift sb
    GROUP BY sb.ss_store_sk, sb.d_year, sb.d_quarter_name, sb.t_shift
),
returns_agg AS (
    SELECT
        rbs.t_shift,
        rbs.d_year,
        rbs.d_quarter_name,
        SUM(rbs.wr_return_quantity) AS total_units_returned,
        SUM(rbs.wr_return_amt) AS total_return_amount
    FROM returns_by_shift rbs
    GROUP BY rbs.t_shift, rbs.d_year, rbs.d_quarter_name
)
SELECT
    st.s_store_name,
    sa.d_year,
    sa.d_quarter_name,
    sa.t_shift,
    sa.total_units_sold,
    sa.total_sales_amount,
    sa.total_net_profit,
    sa.total_promo_cost,
    COALESCE(ra.total_units_returned, 0) AS total_units_returned,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    (sa.total_net_profit - COALESCE(ra.total_return_amount, 0) - sa.total_promo_cost) AS profit_after_returns_and_promos,
    RANK() OVER (PARTITION BY sa.d_year, sa.d_quarter_name ORDER BY (sa.total_net_profit - COALESCE(ra.total_return_amount, 0) - sa.total_promo_cost) DESC) AS store_profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.t_shift = ra.t_shift
    AND sa.d_year = ra.d_year
    AND sa.d_quarter_name = ra.d_quarter_name
JOIN store st ON sa.store_sk = st.s_store_sk
WHERE sa.total_units_sold > 50
ORDER BY sa.d_year, sa.d_quarter_name, store_profit_rank
LIMIT 200
