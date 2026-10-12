WITH agg AS (
    SELECT
        d.d_year AS return_year,
        cc.cc_market_manager,
        r.r_reason_desc,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_store_credit) AS total_store_credit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
      AND cc.cc_market_manager = 'Julius Tran'
      AND cr.cr_return_quantity > 1
      AND w.w_state = 'CA'
    GROUP BY d.d_year, cc.cc_market_manager, r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    return_year,
    cc_market_manager,
    r_reason_desc,
    distinct_orders,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_store_credit,
    RANK() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY return_year, net_loss_rank
