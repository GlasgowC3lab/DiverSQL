WITH sales_hh AS (
    SELECT
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_hdemo_sk
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 30
      AND ss.ss_coupon_amt < 5000
),
returns_hh AS (
    SELECT
        wr.wr_return_quantity,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_reversed_charge,
        wr.wr_refunded_hdemo_sk
    FROM web_returns wr
    WHERE wr.wr_reversed_charge > 100
      AND wr.wr_return_quantity > 0
),
 dim AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM household_demographics hd
    WHERE hd.hd_buy_potential = '501-1000'
)
SELECT
    d.hd_income_band_sk,
    d.hd_buy_potential,
    SUM(s.ss_ext_sales_price) AS total_sales,
    AVG(r.wr_return_amt_inc_tax) AS avg_return_amount,
    SUM(r.wr_return_quantity) AS total_return_qty,
    SUM(s.ss_net_profit) AS total_net_profit,
    SUM(r.wr_net_loss) AS total_return_loss,
    ROW_NUMBER() OVER (ORDER BY SUM(s.ss_ext_sales_price) DESC) AS row_num
FROM dim d
LEFT JOIN sales_hh s
    ON s.ss_hdemo_sk = d.hd_demo_sk
RIGHT OUTER JOIN returns_hh r
    ON r.wr_refunded_hdemo_sk = d.hd_demo_sk
GROUP BY d.hd_income_band_sk, d.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
