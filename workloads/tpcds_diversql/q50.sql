WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        d.word AS channel_word
    FROM
        customer c
        FULL OUTER JOIN web_sales ws
            ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN LATERAL (
            SELECT word
            FROM UNNEST(SPLIT(p.p_channel_details, ' ')) AS t(word)
        ) d ON true
    WHERE
        p.p_response_target = 1
        AND ib.ib_upper_bound >= 50000
        AND hd.hd_buy_potential = '1001-5000'
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY
        p.p_promo_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d.word
),
final_agg AS (
    SELECT
        p_promo_id,
        AVG(total_sales) AS avg_total_sales,
        SUM(distinct_customers) AS sum_distinct_customers
    FROM sales_agg
    GROUP BY p_promo_id
)
SELECT
    p_promo_id,
    avg_total_sales,
    sum_distinct_customers
FROM final_agg
ORDER BY avg_total_sales DESC
LIMIT 100
