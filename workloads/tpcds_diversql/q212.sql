WITH sampled_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_ext_sales_price > 100
),
non_returning_customers AS (
    SELECT c_customer_sk
    FROM customer
    EXCEPT
    SELECT sr_customer_sk
    FROM store_returns
),
joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        c.c_customer_id,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        p.p_promo_name,
        t.t_sub_shift,
        t.t_hour,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM sampled_sales ss
    JOIN non_returning_customers nrc ON ss.ss_customer_sk = nrc.c_customer_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE
        t.t_hour = 12
        AND t.t_sub_shift = 'morning'
        AND hd.hd_vehicle_count >= 1
        AND hd.hd_dep_count <= 5
        AND ib.ib_lower_bound >= 20000
        AND p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT
        c_customer_id,
        hd_income_band_sk,
        t_sub_shift,
        COUNT(*) AS txn_count,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        MIN(ss_ext_sales_price) AS min_sale,
        MAX(ss_ext_sales_price) AS max_sale
    FROM joined_data
    GROUP BY c_customer_id, hd_income_band_sk, t_sub_shift
)
SELECT
    c_customer_id,
    hd_income_band_sk,
    t_sub_shift,
    txn_count,
    total_sales,
    avg_profit,
    min_sale,
    max_sale,
    LAG(total_sales) OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS prev_total_sales
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
