WITH max_year AS (
    SELECT max(d_year) AS max_year
    FROM date_dim
),
sales_agg AS (
    SELECT
        st.s_store_id,
        d.d_year AS year,
        sum(ss.ss_net_paid) AS total_sales,
        sum(ss.ss_net_profit) AS total_profit,
        sum(ss.ss_ext_discount_amt) AS total_discount,
        row_number() OVER (PARTITION BY st.s_store_id ORDER BY sum(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY st.s_store_id, d.d_year
),
returns_agg AS (
    SELECT
        st.s_store_id,
        d.d_year AS year,
        sum(sr.sr_net_loss) AS total_loss,
        sum(sr.sr_refunded_cash) AS total_refund
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    GROUP BY st.s_store_id, d.d_year
)
SELECT
    sa.s_store_id,
    sa.year,
    sa.total_sales,
    sa.total_profit,
    coalesce(ra.total_loss, 0) AS total_loss,
    (sa.total_profit - coalesce(ra.total_loss, 0)) AS net_profit,
    round(((sa.total_profit - coalesce(ra.total_loss, 0)) / nullif(sa.total_sales, 0)) * 100, 2) AS profit_margin_percent,
    sa.profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id AND sa.year = ra.year
WHERE sa.year >= (SELECT max_year - 5 FROM max_year)
ORDER BY net_profit DESC
LIMIT 100
