WITH
    filtered_returns AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_refunded_hdemo_sk,
            cr.cr_returning_hdemo_sk,
            cr.cr_order_number,
            cr.cr_return_amount,
            cr.cr_net_loss
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
    ),
    agg_returns AS (
        SELECT
            fr.cr_returned_date_sk,
            fr.cr_item_sk,
            fr.cr_refunded_hdemo_sk,
            fr.cr_returning_hdemo_sk,
            fr.cr_order_number,
            SUM(fr.cr_return_amount) AS total_return_amount,
            SUM(fr.cr_net_loss) AS total_net_loss,
            COUNT(*) AS cnt
        FROM filtered_returns fr
        JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY
            fr.cr_returned_date_sk,
            fr.cr_item_sk,
            fr.cr_refunded_hdemo_sk,
            fr.cr_returning_hdemo_sk,
            fr.cr_order_number
    ),
    except_orders AS (
        SELECT cr_order_number FROM catalog_returns
        EXCEPT
        SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 100
    )
SELECT
    i.i_brand_id,
    i.i_brand,
    ib_refunded.ib_lower_bound AS refunded_income_lower,
    ib_returning.ib_upper_bound AS returning_income_upper,
    ar.total_return_amount,
    ar.total_net_loss,
    ar.cnt AS return_cnt,
    LAG(ar.total_return_amount) OVER (PARTITION BY i.i_brand_id ORDER BY ar.total_return_amount DESC) AS lag_return_amount,
    SUM(ar.total_return_amount) OVER (PARTITION BY i.i_brand_id ORDER BY ar.total_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return
FROM agg_returns ar
JOIN item i ON ar.cr_item_sk = i.i_item_sk
JOIN item i2 ON ar.cr_item_sk = i2.i_item_sk
JOIN household_demographics hd_refunded ON ar.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib_refunded ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
JOIN household_demographics hd_returning ON ar.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN income_band ib_returning ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
JOIN income_band ib_extra ON hd_returning.hd_income_band_sk = ib_extra.ib_income_band_sk
JOIN date_dim d2 ON ar.cr_returned_date_sk = d2.d_date_sk
WHERE i.i_item_sk IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_return_amount > 50)
  AND ar.cr_order_number IN (SELECT cr_order_number FROM except_orders)
ORDER BY i.i_brand_id, ar.total_return_amount DESC
LIMIT 100
