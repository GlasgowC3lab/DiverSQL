WITH returns_summary AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_brand,
        SUM(cr.cr_return_amount) AS total_return_amt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(p.p_cost) AS avg_promo_cost
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk <= d.d_date_sk
        AND p.p_end_date_sk >= d.d_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price BETWEEN 10 AND 100
        AND p.p_discount_active = 'Y'
        AND ca_ref.ca_location_type = 'apartment'
        AND hd_ref.hd_income_band_sk = 5
        AND cr.cr_return_quantity > 1
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_returned_date_sk = cr.cr_returned_date_sk
              AND wr.wr_item_sk = cr.cr_item_sk
        )
    GROUP BY d.d_year, i.i_item_id, i.i_brand
)
SELECT
    d_year,
    SUM(total_return_amt) AS year_total_return_amt,
    AVG(total_net_loss) AS avg_net_loss_per_item,
    SUM(return_cnt) AS total_returns,
    AVG(avg_promo_cost) AS overall_avg_promo_cost
FROM returns_summary
GROUP BY d_year
HAVING AVG(total_net_loss) > 1000
ORDER BY year_total_return_amt DESC
LIMIT 100
