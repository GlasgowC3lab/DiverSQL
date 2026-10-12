WITH sales AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid_inc_tax
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity >= 14
      AND cs.cs_net_paid_inc_ship_tax > 500
      AND cs.cs_ext_discount_amt > 500
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
returns AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_return_customers,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT s.s_store_name) AS distinct_stores
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_amt > 100
    GROUP BY ib.ib_income_band_sk
)
SELECT
    s.ib_lower_bound,
    s.ib_upper_bound,
    s.distinct_customers,
    r.distinct_return_customers,
    r.distinct_stores,
    s.total_net_profit,
    r.total_return_loss,
    (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    (s.total_net_profit - COALESCE(r.total_return_loss, 0)) / NULLIF(s.distinct_customers, 0) AS profit_per_customer,
    RANK() OVER (ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
    ON s.ib_income_band_sk = r.ib_income_band_sk
WHERE (s.total_net_profit - COALESCE(r.total_return_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 20
