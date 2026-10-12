WITH total_return AS (
    SELECT SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_quantity > 0
),
income_band_averages AS (
    SELECT AVG(ib_lower_bound) AS avg_lower,
           AVG(ib_upper_bound) AS avg_upper
    FROM income_band
),
sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_id,
        p.p_promo_id AS promo_id,
        p.p_channel_tv,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_coupon_amt) AS total_coupon_amount,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_tv = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ss.ss_store_sk, p.p_promo_id, p.p_channel_tv
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    sa.store_id,
    sa.promo_id,
    sa.p_channel_tv,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.total_coupon_amount,
    sa.sales_cnt,
    sa.avg_discount,
    tr.total_return_amount,
    iba.avg_lower,
    iba.avg_upper,
    RANK() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM sales_agg sa
CROSS JOIN total_return tr
CROSS JOIN income_band_averages iba
ORDER BY profit_rank
LIMIT 100
