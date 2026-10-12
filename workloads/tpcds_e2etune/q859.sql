WITH agg AS (
    SELECT
        cc.cc_name,
        cc.cc_manager,
        cc.cc_state,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_tax) AS total_tax
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND c_refunded.c_preferred_cust_flag = 'Y'
      AND c_returning.c_birth_year >= 1990
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY cc.cc_name, cc.cc_manager, cc.cc_state
    HAVING COUNT(*) > 100
)
SELECT
    agg.*, 
    RANK() OVER (ORDER BY agg.total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 10
