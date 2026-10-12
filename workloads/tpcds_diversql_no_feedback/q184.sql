WITH returns_agg AS (
        SELECT
            sr_ticket_number,
            SUM(sr_return_quantity) AS total_return_qty,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_net_loss) AS total_net_loss
        FROM store_returns
        WHERE sr_return_quantity > 0
          AND sr_return_amt > 0
        GROUP BY sr_ticket_number
    )
SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    ss.ss_ext_sales_price,
    ss.ss_ext_discount_amt,
    ss.ss_net_profit,
    COALESCE(ra.total_return_amt, 0) AS total_return_amt,
    (ss.ss_ext_sales_price - COALESCE(ra.total_return_amt, 0)) AS net_sales_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY ss.ss_store_sk
        ORDER BY (ss.ss_ext_sales_price - COALESCE(ra.total_return_amt, 0)) DESC
    ) AS rn_store_rank
FROM store_sales ss
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN returns_agg ra
    ON ss.ss_ticket_number = ra.sr_ticket_number
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_marital_status = 'M'
  AND ib.ib_lower_bound >= 120000
  AND p.p_discount_active = 'Y'
  AND ss.ss_ext_sales_price > 1000
ORDER BY net_sales_after_returns DESC
LIMIT 100
